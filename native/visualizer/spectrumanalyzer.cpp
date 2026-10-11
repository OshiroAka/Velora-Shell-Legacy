#include "spectrumanalyzer.hpp"

#include <QMetaObject>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>

#include <fftw3.h>
#include <pulse/simple.h>

namespace {
constexpr int kSampleRate = 16000;
constexpr int kChannels = 2;
constexpr int kFftSize = 2048;
constexpr int kBars = 96;
constexpr int kFrameRate = 60;
constexpr float kMinFrequency = 35.F;
constexpr float kMaxFrequency = 7600.F;
constexpr float kAttack = 0.72F;
constexpr float kRelease = 0.20F;
constexpr float kNoiseFloor = 0.035F;
constexpr float kAmplify = 1.72F;
constexpr float kSignalFloor = 0.0005F;
}

SpectrumAnalyzer::SpectrumAnalyzer(QObject* parent)
    : QObject(parent)
    , values_(kBars, 0.F)
    , worker_([this](std::stop_token token) { run(token); }) {}

SpectrumAnalyzer::~SpectrumAnalyzer() {
    worker_.request_stop();
    activationChanged_.notify_all();
}

bool SpectrumAnalyzer::active() const noexcept {
    return active_.load(std::memory_order_relaxed);
}

void SpectrumAnalyzer::setActive(bool value) {
    if (active_.exchange(value, std::memory_order_relaxed) == value)
        return;
    emit activeChanged();
    activationChanged_.notify_all();
}

bool SpectrumAnalyzer::running() const noexcept {
    return running_.load(std::memory_order_relaxed);
}

int SpectrumAnalyzer::bandCount() const noexcept {
    return running() ? kBars : 0;
}

bool SpectrumAnalyzer::hasSignal() const noexcept {
    return hasSignal_.load(std::memory_order_relaxed);
}

std::vector<float> SpectrumAnalyzer::values() const {
    std::scoped_lock lock(valuesMutex_);
    return values_;
}

QString SpectrumAnalyzer::materialFrame() const {
    // One bounded snapshot for the compositor's shared bar material. Capture
    // and FFT remain in this analyzer; no second audio producer is started.
    QString result;
    result.reserve(700);
    for (float value : values()) {
        result += QLatin1Char(' ');
        result += QString::number(std::clamp(value, 0.F, 1.F), 'f', 4);
    }
    return result;
}

void SpectrumAnalyzer::setRunning(bool value) {
    if (running_.exchange(value, std::memory_order_relaxed) == value)
        return;
    QMetaObject::invokeMethod(this, [this] { emit runningChanged(); },
                              Qt::QueuedConnection);
}

void SpectrumAnalyzer::publish(const std::vector<float>& values, bool hasSignal) {
    {
        std::scoped_lock lock(valuesMutex_);
        values_ = values;
    }

    const bool signalChanged = hasSignal_.exchange(
        hasSignal, std::memory_order_relaxed) != hasSignal;
    QMetaObject::invokeMethod(this, [this, signalChanged] {
        emit bandsChanged();
        if (signalChanged)
            emit hasSignalChanged();
    }, Qt::QueuedConnection);
}

void SpectrumAnalyzer::clearValues() {
    publish(std::vector<float>(kBars, 0.F), false);
}

void SpectrumAnalyzer::run(std::stop_token stopToken) {
    const int chunkFrames = std::max(
        128, static_cast<int>(std::lround(
            kSampleRate / static_cast<double>(kFrameRate))));
    const pa_sample_spec sampleSpec{PA_SAMPLE_FLOAT32LE, kSampleRate, kChannels};
    const pa_buffer_attr bufferAttributes{
        std::numeric_limits<std::uint32_t>::max(),
        std::numeric_limits<std::uint32_t>::max(),
        std::numeric_limits<std::uint32_t>::max(),
        std::numeric_limits<std::uint32_t>::max(),
        static_cast<std::uint32_t>(chunkFrames * kChannels
                                   * static_cast<int>(sizeof(float)))
    };

    std::vector<float> window(kFftSize);
    std::vector<float> targetBins(kBars);
    constexpr float pi = 3.14159265358979323846F;
    for (int index = 0; index < kFftSize; ++index)
        window[index] = 0.5F - 0.5F * std::cos(
            (2.F * pi * static_cast<float>(index))
            / static_cast<float>(kFftSize - 1));
    for (int index = 0; index < kBars; ++index) {
        const float progress = static_cast<float>(index)
            / static_cast<float>(kBars - 1);
        const float frequency = kMinFrequency
            * std::pow(kMaxFrequency / kMinFrequency, progress);
        targetBins[index] = frequency * static_cast<float>(kFftSize)
            / static_cast<float>(kSampleRate);
    }

    std::vector<float> history(kFftSize, 0.F);
    std::vector<float> capture(
        static_cast<std::size_t>(chunkFrames * kChannels));
    std::vector<float> fftInput(kFftSize);
    std::vector<fftwf_complex> fftOutput(kFftSize / 2 + 1);
    std::vector<float> spectrum(kFftSize / 2 + 1);
    std::vector<float> smoothed(kBars, 0.F);
    std::vector<std::int16_t> encoded(kBars, 0);
    std::vector<std::int16_t> previousEncoded(kBars, 0);
    fftwf_plan plan = fftwf_plan_dft_r2c_1d(
        kFftSize, fftInput.data(), fftOutput.data(), FFTW_ESTIMATE);
    if (!plan)
        return;

    while (!stopToken.stop_requested()) {
        {
            std::unique_lock lock(activationMutex_);
            activationChanged_.wait(lock, stopToken, [this] {
                return active_.load(std::memory_order_relaxed);
            });
        }
        if (stopToken.stop_requested())
            break;

        int pulseError = 0;
        pa_simple* pulse = pa_simple_new(
            nullptr, "velora-visualizer-spectrum", PA_STREAM_RECORD,
            "@DEFAULT_MONITOR@", "Velora Shell native spectrum",
            &sampleSpec, nullptr, &bufferAttributes, &pulseError);
        if (!pulse) {
            std::unique_lock lock(activationMutex_);
            activationChanged_.wait_for(lock, stopToken,
                std::chrono::milliseconds(500), [this] {
                    return !active_.load(std::memory_order_relaxed);
                });
            continue;
        }

        std::fill(history.begin(), history.end(), 0.F);
        std::fill(smoothed.begin(), smoothed.end(), 0.F);
        std::fill(encoded.begin(), encoded.end(), 0);
        std::fill(previousEncoded.begin(), previousEncoded.end(), 0);
        bool hasPrevious = false;
        int skippedFrames = 0;

        setRunning(true);
        while (!stopToken.stop_requested()
               && active_.load(std::memory_order_relaxed)) {
            if (pa_simple_read(pulse, capture.data(),
                               capture.size() * sizeof(float),
                               &pulseError) < 0)
                break;
            if (!active_.load(std::memory_order_relaxed))
                break;

            const int shift = std::min(chunkFrames, kFftSize);
            std::move(history.begin() + shift, history.end(), history.begin());
            const int destination = kFftSize - shift;
            const int sourceBase = (chunkFrames - shift) * kChannels;
            for (int frame = 0; frame < shift; ++frame) {
                const int source = sourceBase + frame * kChannels;
                history[destination + frame] = 0.5F
                    * (capture[source] + capture[source + 1]);
            }
            for (int index = 0; index < kFftSize; ++index)
                fftInput[index] = history[index] * window[index];

            fftwf_execute(plan);
            float peak = 0.0001F;
            for (std::size_t index = 0; index < spectrum.size(); ++index) {
                spectrum[index] = std::log1p(std::hypot(
                    fftOutput[index][0], fftOutput[index][1]));
                peak = std::max(peak, spectrum[index]);
            }

            float visualPeak = 0.F;
            int maximumDifference = 0;
            for (int index = 0; index < kBars; ++index) {
                const float position = std::clamp(
                    targetBins[index], 0.F,
                    static_cast<float>(spectrum.size() - 1));
                const int lower = static_cast<int>(position);
                const int upper = std::min(
                    lower + 1, static_cast<int>(spectrum.size() - 1));
                const float fraction = position - static_cast<float>(lower);
                const float normalized = ((1.F - fraction) * spectrum[lower]
                    + fraction * spectrum[upper]) / peak;
                const float value = 1.F - std::exp(
                    -std::max(0.F, normalized - kNoiseFloor) * kAmplify);
                const float smoothing = value >= smoothed[index]
                    ? kAttack : kRelease;
                smoothed[index] += (value - smoothed[index]) * smoothing;
                visualPeak = std::max(visualPeak, smoothed[index]);
                encoded[index] = static_cast<std::int16_t>(
                    std::lround(smoothed[index] * 1000.F));
                if (hasPrevious) {
                    maximumDifference = std::max(maximumDifference,
                        std::abs(static_cast<int>(encoded[index])
                                 - static_cast<int>(previousEncoded[index])));
                }
            }

            if (hasPrevious && maximumDifference <= 1) {
                ++skippedFrames;
                if (skippedFrames < std::max(2, kFrameRate / 12))
                    continue;
            }
            skippedFrames = 0;
            hasPrevious = true;
            previousEncoded = encoded;
            publish(smoothed, visualPeak > kSignalFloor);
        }

        setRunning(false);
        clearValues();
        pa_simple_free(pulse);
    }

    fftwf_destroy_plan(plan);
}

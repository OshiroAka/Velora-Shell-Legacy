#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

#include <atomic>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <vector>

class SpectrumAnalyzer : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(SpectrumAnalyzer)

    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(int bandCount READ bandCount NOTIFY runningChanged)
    Q_PROPERTY(bool hasSignal READ hasSignal NOTIFY hasSignalChanged)

public:
    explicit SpectrumAnalyzer(QObject* parent = nullptr);
    ~SpectrumAnalyzer() override;
    Q_DISABLE_COPY_MOVE(SpectrumAnalyzer)

    [[nodiscard]] bool active() const noexcept;
    void setActive(bool value);
    [[nodiscard]] bool running() const noexcept;
    [[nodiscard]] int bandCount() const noexcept;
    [[nodiscard]] bool hasSignal() const noexcept;
    [[nodiscard]] std::vector<float> values() const;
    Q_INVOKABLE QString materialFrame() const;

signals:
    void activeChanged();
    void runningChanged();
    void hasSignalChanged();
    void bandsChanged();

private:
    void run(std::stop_token stopToken);
    void setRunning(bool value);
    void publish(const std::vector<float>& values, bool hasSignal);
    void clearValues();

    mutable std::mutex valuesMutex_;
    std::vector<float> values_;
    std::atomic_bool active_{false};
    std::atomic_bool running_{false};
    std::atomic_bool hasSignal_{false};
    std::mutex activationMutex_;
    std::condition_variable_any activationChanged_;
    std::jthread worker_;
};

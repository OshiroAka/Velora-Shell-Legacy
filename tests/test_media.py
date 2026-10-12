import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import time
import unittest
from unittest.mock import patch
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def load_script(name):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / "scripts" / name))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class MediaPanelTests(unittest.TestCase):
    def test_transport_search_focus_and_lyrics_motion(self):
        runner = "/usr/lib/qt6/bin/qmltestrunner"
        if not Path(runner).exists():
            self.skipTest("Qt 6 Quick Test is required")
        with tempfile.TemporaryDirectory(prefix="velora-media-test-") as temporary:
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=temporary)
            result = subprocess.run([runner, "-input", str(ROOT / "tests/fixtures/tst_media_panel.qml")],
                                    env=env, capture_output=True, text=True, timeout=25)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn("QWARN", output)
            self.assertNotIn("ReferenceError", output)


class MediaLyricsTests(unittest.TestCase):
    def cached_lyrics(self, data):
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, {"XDG_CACHE_HOME": temporary}):
            source = load_script("velora-lyrics-state")
            library = load_script("velora-media-library")
            meta = {"title": "Fixture", "artist": "Velora", "album": "Tests", "duration": 100}
            source.write_cache(meta, dict(ok=True, **data))
            # A warm cache must work without a network connection.
            with patch("urllib.request.urlopen", side_effect=AssertionError("unexpected network")):
                return library.lyrics(meta)

    def test_cached_timeline_keeps_real_timestamps(self):
        result = self.cached_lyrics({"syncedLyrics": "[00:01.00]First original line\n[00:12.50]Second original line"})
        self.assertTrue(result["synced"])
        self.assertEqual([line["time"] for line in result["lines"]], [1.0, 12.5])

    def test_plain_lyrics_are_not_assigned_invented_timing(self):
        result = self.cached_lyrics({"plainLyrics": "One original line\n\nAnother original line"})
        self.assertFalse(result["synced"])
        self.assertEqual([line["time"] for line in result["lines"]], [-1, -1])


class SpotifyBridgeTests(unittest.TestCase):
    def setUp(self):
        self.bridge = load_script("velora-spotify-bridge")
        self.temporary = tempfile.TemporaryDirectory()
        self.bridge.CACHE = Path(self.temporary.name)
        self.bridge.TOKEN = "test-private-token"
        self.server = self.bridge.ThreadingHTTPServer(("127.0.0.1", 0), self.bridge.Handler)
        self.server.daemon_threads = True
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = "http://127.0.0.1:" + str(self.server.server_port)

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)
        self.temporary.cleanup()

    def request(self, path, data=None, token=True, origin=None):
        headers = {"Content-Type": "application/json"}
        if token:
            headers["X-Velora-Token"] = self.bridge.TOKEN
        if origin:
            headers["Origin"] = origin
        request = urllib.request.Request(self.url + path,
            data=json.dumps(data).encode() if data is not None else None, headers=headers)
        with urllib.request.urlopen(request, timeout=4) as response:
            return json.load(response)

    def test_private_commands_origin_and_closed_client(self):
        command = {"action": "search", "query": "Velora"}
        with self.assertRaises(urllib.error.HTTPError) as error:
            self.request("/command", command, token=False)
        self.assertEqual(error.exception.code, 403)
        error.exception.close()
        with self.assertRaises(urllib.error.HTTPError) as error:
            self.request("/queue", {"next": []}, origin="https://unrelated.example")
        self.assertEqual(error.exception.code, 403)
        error.exception.close()
        self.assertEqual(self.request("/command", command)["reason"], "spotify-offline")
        with self.assertRaises(urllib.error.HTTPError) as error:
            self.request("/command", {"action": "arbitrary", "query": "Velora"})
        self.assertEqual(error.exception.code, 400)
        error.exception.close()

    def test_search_round_trip_and_queue_artwork(self):
        self.bridge.LAST_CLIENT = time.monotonic()
        result = {}
        def search():
            result.update(self.request("/command", {"action": "search", "query": "Velora"}))
        worker = threading.Thread(target=search)
        worker.start()
        requests = self.request("/requests", token=False, origin="https://xpui.app.spotify.com")["requests"]
        self.assertEqual(requests[0]["query"], "Velora")
        track = {"title": "Original fixture", "artist": "Velora", "uri": "spotify:track:abc123", "art": "spotify:image:fixture"}
        self.request("/result", {"id": requests[0]["id"], "ok": True, "tracks": [track]}, token=False)
        worker.join(timeout=4)
        self.assertFalse(worker.is_alive())
        self.assertTrue(result["ok"])
        self.assertEqual(result["tracks"][0]["art"], "https://i.scdn.co/image/fixture")
        self.assertFalse(self.bridge.PENDING)
        self.request("/queue", {"current": track, "next": [track], "revision": "fixture"}, token=False)
        cache = json.loads((self.bridge.CACHE / "spotify-queue.json").read_text())
        self.assertEqual(cache["next"][0]["uri"], track["uri"])


if __name__ == "__main__":
    unittest.main()

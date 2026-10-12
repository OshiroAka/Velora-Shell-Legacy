# Validation

Run the suite from the checkout:

```sh
./tests/run
```

The suite uses Python 3, Node.js, Quickshell, Qt 6 Quick Test, a C++20 compiler,
`pkg-config`, EGL and OpenGL ES development libraries. Installation and helper
checks use temporary homes and mocked commands. The Spotify bridge tests bind
to an ephemeral port on `127.0.0.1`; a sandbox must permit local sockets.
QML tests use offscreen rendering. GPU/material checks exercise the native
shader independently of the active desktop.

Focused checks:

```sh
python3 -m unittest discover -s tests -p test_edge_media.py
python3 -m unittest discover -s tests -p test_rail_system.py
python3 -m unittest discover -s tests -p test_settings_rebuild.py
```

Edge media coverage includes transport controls, curved lyrics, the bundled
serif font, smooth verse scrolling, glow handoff, audio demand, reduced motion,
full-height closing, reentry during closing and volume/brightness coexistence.
Rail coverage includes geometry handoff, rapid reversal, delayed slider content,
closing and reduced motion.

Offscreen tests do not replace visual review on a compositor or physical
multi-monitor and hardware checks.

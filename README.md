# Moo Rush

Moo Rush: Corn to Capitol — farm-to-President tycoon game with zombie nights, built from an HTML prototype toward a native mobile app

Scaffolded with noamcli. See `AGENTS.md` for layout and working rules; `context/STATE.md` for current state.

Run the native Chapter 1 slice with `godot --path godot`; move with WASD/arrows or drag a touch joystick. Choose one of three save slots. Run `./check.sh` for the headless checks.

Build Android: `mkdir -p build`, then `godot --headless --path godot --export-debug Android "$PWD/build/moorush-debug.apk"`. Toolchain setup: `context/architecture/tech-stack.md`. The slice ends at the dairy gate; later chapters and combat remain to be ported.

For a visible automated Chapter 1 playthrough: `godot --path godot -s res://tests/test_windowed_chapter1.gd`. It follows the guide through real movement, captures frames in `build/playtest-*.png`, and exits at the dairy gate. It uses an isolated test save directory.

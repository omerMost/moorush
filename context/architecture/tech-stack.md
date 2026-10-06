<!--
What this file answers: what did we pick for each layer of the project, and why.
When to update: any time a new dependency is locked in, swapped, or removed — same turn as the code change.
Example entry: "UI framework: Expo Router 7 — file-based routing, already Expo-blessed."
Seed this file during install (don't leave blank) — stack choices are usually known up-front. If you genuinely don't have an answer for a section yet, write "TBD" instead of deleting the section.
-->

# Tech stack

One section per layer. For each choice: what we picked + one-line rationale. Resist writing prose — this is a lookup table, not an essay.

## Runtime / language

- Prototype: vanilla JavaScript, one HTML file (`prototype/index.html`), no build step.
- Native app: **Godot 4.7.x + GDScript** in `godot/` (ADR 0005). Android first. Built as a chapter-1 slice first, keeping the code-drawn look (`_draw()`).
- The prototype is now a frozen **spec**. No new features go into it.

## UI / presentation layer

- Frozen prototype: Canvas 2D, procedural sprites/emoji, DOM HUD and Baloo 2 from Google Fonts.
- Native drawing cache (ADR 0006): four procedural 4× item textures baked at runtime, bounded curve/text caches and batched grass; no external sprite art or added dependencies.
- Native: `Paint`/`world_view.gd` code drawing and `hud.gd` controls. Logical 540×960 canvas_items viewport, expand aspect, portrait; bundled Baloo 2 variable font at weight 800 (OFL), OS emoji fallback.

## Audio

- `MooAudio` (`audio.gd`): prototype tone sequences baked into 44.1kHz mono AudioStreamWAV clips at startup; eight reusable voices and rate limits. Menu mute persists separately from saves (ADR 0007, provisional). No external audio assets/backend.

## Data layer

- Prototype content is JS object literals in the file: `STAGES`, `HARBOR`, `VEHICLES`, `GUNS`, and the `PM`/`TUNE` economy multipliers. There is no backend. Native Farm Kid data lives in `godot/scripts/data.gd`; `MooSim` owns simulation state.

## Auth / storage / persistence

- Native saves: 3 JSON files under `user://`, with snapshot/apply_state in `sim.gd`. Current-version keyed saves preserve partial payments; full legacy HTML import remains pending.
- Prototype saves: localStorage, with 3 slots, settings, and migration from v1 and older versions. Cloud: `window.claude` db/user, inside claude.ai only.

## External integrations

- None yet.

## Tooling (build, test, lint, CI)

- Tests: **headless Godot bots** behind `check.sh` (ADR 0005, G4). Implemented: import/boot, gate bot, unattended counters, populated saves and phone-sized touch HUD/font and audio waveform/settings/dispatch. Nonzero processes and engine errors fail. No HTML suite.
- Optional rendered smoke test: `godot --path godot -s res://tests/test_windowed_chapter1.gd` (requires a display); runs the career through the main scene with 90s/240s/completion captures under `build/`, in isolated test storage.
- Prototype: test hook `window.__moo`. Local run: the `prototype` config in `.claude/launch.json` (port 8090).
- **Android export toolchain (installed 2026-10-07, proven by a probe APK).** To redo it on a fresh Mac:
  1. **JDK 17:** `brew install openjdk@17`. JAVA_HOME = `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` (it's keg-only and not on PATH; `/usr/bin/java` is only a stub).
  2. **SDK command-line tools 15859902:** download `https://dl.google.com/android/repository/commandlinetools-mac_arm64-15859902_latest.zip` (156 MB, sha256 `835b62a2…5002c4e`, the same one the brew cask uses) and unzip its `cmdline-tools/` folder to `~/Library/Android/sdk/cmdline-tools/latest/`.
  3. **SDK packages** (the versions Godot 4.7.2 pins in `platform/android/java/app/config.gradle`): `yes | sdkmanager --sdk_root=$HOME/Library/Android/sdk --licenses`, then `sdkmanager --sdk_root=$HOME/Library/Android/sdk "platform-tools" "build-tools;36.1.0" "platforms;android-36"`. Run it with JAVA_HOME set. That installs platform-tools 37.0.1. The NDK 29 and CMake 3.22.1 are **not** installed: only the Gradle build needs them.
  4. **Export templates 4.7.2.stable:** `Godot_v4.7.2-stable_export_templates.tpz` from the GitHub release (1.28 GB; check it against the release's `SHA512-SUMS.txt`, `ca4d71c4…29cff1`). Only `templates/{version.txt,android_debug.apk,android_release.apk,android_source.zip}` are kept, extracted flat into `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (≈450 MB).
  5. **Debug keystore:** `keytool -genkeypair -keystore "~/Library/Application Support/Godot/keystores/debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`.
  6. **Editor settings** (`~/Library/Application Support/Godot/editor_settings-4.7.tres`): `export/android/java_sdk_path` = the JAVA_HOME above, `export/android/android_sdk_path = "/Users/omer/Library/Android/sdk"`, `export/android/debug_keystore` = the keystore above, `debug_keystore_pass = "android"`. Close the Godot editor before you edit this file, because an open editor can write its own copy back over it.
  7. **Build:** the preset is `Android` with `gradle_build/use_gradle_build=false` and `arm64-v8a` only. From the repo root run `mkdir -p build`, then `godot --headless --path godot --export-debug "Android" "$PWD/build/moorush-debug.apk"` (an absolute output avoids Godot resolving it inside `godot/`). Godot runs `apksigner` itself. Check the result with `~/Library/Android/sdk/build-tools/36.1.0/aapt dump badging <apk>`; it prints a harmless `android:required` attribute warning. Output: minSdk 24, targetSdk 36.
  - The committed preset is `godot/export_presets.cfg`, package `com.omer.moorush`, version 0.1.3. `scripts/generate-icons.js` also generates the native placeholder icon. No Internet permission.
  - Build outputs (`build/`, `*.apk`, `*.aab`, `*.idsig`, `.godot/`) are gitignored.

## What we deliberately did NOT pick

_(Things that were on the table and lost. Each entry: what it was, why it lost. Saves future-you from re-litigating.)_

- **Capacitor wrapping the HTML.** It's a web view with canvas performance limits (ADR 0005).
- **A Playwright suite on the HTML.** The tests live in Godot only (ADR 0005).
- **New sprite art during the port.** We keep the code-drawn look for now (ADR 0005).

- Android listening follow-up: +6dB playback gain (bounded precomputed peaks retain headroom), explicit ON/OFF and a menu Test sound cue; audible phone validation remains pending.

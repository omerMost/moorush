# 2026-10-07 — Android export toolchain

**Agent:** Root Orchestrator (did it alone; no subagents). **Backlog:** Now → "Android toolchain" (done).

## What changed
- **JDK 17:** `brew install openjdk@17` installed 17.0.20.1. It's keg-only; JAVA_HOME = `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- **Android SDK** in `~/Library/Android/sdk`:
  - cmdline-tools 15859902, the zip checked with sha256 and placed in `cmdline-tools/latest`;
  - platform-tools 37.0.1, build-tools 36.1.0 and platforms;android-36, which are the versions Godot 4.7.2's `config.gradle` pins;
  - the licenses were accepted (card T2);
  - no NDK or CMake, because we don't use the Gradle build.
- **Export templates** 4.7.2.stable: the 1.28 GB `.tpz` (card T1) had its SHA-512 checked against the release's SHA512-SUMS. Only the Android files were extracted, into `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
- **Debug keystore** created at `~/Library/Application Support/Godot/keystores/debug.keystore`, the path the editor settings already pointed to. `editor_settings-4.7.tres` got `export/android/java_sdk_path`; the SDK path was already set. A backup was kept as `.bak-<epoch>`.
- **Repo:**
  - `architecture/tech-stack.md` has the full step-by-step install recipe;
  - `.gitignore` gains `build/`, `*.apk`, `*.aab`, `*.idsig` and `.godot/`;
  - STATE, the backlog and done are updated.
- `godot/` is **not on `main`** yet; it exists only in the parallel worktree `laughing-varahamihira-4a3a35`, which I didn't touch. So I proved the toolchain with a throwaway probe project in the scratchpad (Node2D plus a Label, preset `Android`, arm64-v8a only, no Gradle). The slice APK is now the backlog item "Slice APK".

## Checks
- `java -version` → OpenJDK 17.0.20.1.
- `sdkmanager --list_installed` → build-tools;36.1.0, platform-tools 37.0.1, platforms;android-36.
- The templates' SHA-512 matches `ca4d71c4…29cff1`, and `version.txt` = `4.7.2.stable`.
- `godot --headless --path mini --export-debug "Android" build/probe-debug.apk` gives `[ DONE ] export`, "Signed", and a 28 MB APK.
- `aapt dump badging` → `package: name='com.omer.moorush.probe' versionCode='1'`, `sdkVersion:'24'`, `targetSdkVersion:'36'`, and the label "Moo Probe". There's one harmless `android:required` attribute warning.
- `apksigner verify --print-certs` → signer `CN=Android Debug, O=Android, C=US`.
- There's no `check.sh` in the repo yet, so there was nothing to run. Only docs and `.gitignore` changed.

## Risks / notes
- A Godot editor (PID 29019, started 00:13) was open while I edited `editor_settings-4.7.tres`. If it saves its own settings later, it could wipe `java_sdk_path`. I re-checked after the export and the path was still there. If an export later says "Java SDK path missing", set it again (tech-stack step 6).
- *Provisional* choices I made alone:
  - arm64-v8a only;
  - no Gradle build and no NDK;
  - the templates trimmed to Android only (≈450 MB on disk instead of 1.28 GB).

## Decision cards
- **T1** (download the 1.28 GB templates): A, Download.
- **T2** (accept the Android SDK licenses): A, Accept.

## Dialogue trace
- User (the session brief): "GOAL: make this Mac able to export the Godot project to an Android debug APK." … "Ask the user before any download over 1 GB, and tell them its size."
- T1 answer: "A: Download (Recommended)".
- T2 answer: "A: Accept (Recommended)".

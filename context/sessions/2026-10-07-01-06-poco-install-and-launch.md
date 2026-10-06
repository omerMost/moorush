# POCO Android installation and launch

## What changed
- Connected/authorized user phone, model 2412DPC0AG (user calls it POCO X7).
- Xiaomi initially returned INSTALL_FAILED_USER_RESTRICTED. User enabled Install via USB; retry with phone prompt accepted succeeded.
- Installed existing com.omer.moorush 0.1.0 debug APK and launched its resolved GodotAppLauncher activity. No game code changed.
- STATE/backlog reflect installation and startup evidence; actual touch/performance/save lifecycle playtest remains pending.

## Checks
- adb streamed install: Success.
- am start -W: Status ok, cold launch 689ms; process remains alive.
- App-scoped logcat: Godot setup/main loop started, Vulkan 1.3.278 / Mali-G720 MC7. No Godot script error or fatal crash found in startup log. Vendor/audio warnings are not claimed as absent.
- No code changed; prior headless checks remain green. This is startup verification, not a full Android playthrough.

## Dialogue trace
- User: "connected the phone"
- User: "i have a xiomi phone poco x7"
- User enabled USB debugging and Install via USB, replying "done".

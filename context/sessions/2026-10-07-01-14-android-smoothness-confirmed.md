# Android smoothness confirmed

## What changed
- Recorded user's v0.1.1 feedback verbatim: "yes much better".
- Read app debug timing from connected POCO: four five-second windows report 99.9, 99.4, 82.7, 78.4 engine FPS; frame p95 10.42–13.33ms and mean world draw CPU 5.91–7.71ms.
- Closed smoothness validation backlog item, updated STATE/playtest/done, accepted ADR 0006 following user validation and removed provisional architecture labels.
- No code changed. Long-run thermal behavior, layout checks and suspend/resume saves remain in device playtest backlog.

## Checks
- Read-only adb connection and app logcat. Values are engine frame intervals, not compositor presentation FPS; approximately 20s of windows, not a sustained benchmark.
- Docs only; prior code checks remain green. git diff --check.

## Dialogue trace
- User: "yes much better"

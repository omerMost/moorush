# Android saves after close/reopen confirmed

## What changed
- User requested close; adb force-stopped Moo Rush and verified no process remained.
- User requested start; cold launch succeeded in 602ms.
- User confirms progress saved. Recorded in playtest/STATE/done; narrowed remaining device checks. No code changed.

## Checks
- On-device user verification following force-stop and cold launch. Does not establish every background/suspend lifecycle or save instant.
- Docs only; git diff --check. Prior code checks remain green.

## Dialogue trace
- User: "close the game"
- User: "start it"
- User: "yes it saves"

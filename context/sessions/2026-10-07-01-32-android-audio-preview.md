# Android audio listening follow-up

## Changes
- User's 0.1.2 retest remained silent. Added menu Test sound button (stage celebration), disabled when muted; enabling sound emits a confirmation coin cue.
- Raised voice playback gain by 6dB, retaining waveform headroom. Provisional listening aid documented in ADR 0007; root cause is unproven.
- Version 0.1.3 installed and cold launched (451ms), preserving sound=true. Tests now route real pointer events to the preview and verify cue scheduling at both phone sizes.

## Checks
- `./check.sh`: GREEN including real pointer toggle/preview, menu bounds, audio waveform/mute/persistence, slots and gameplay bots. Final signed APK re-export after test-node naming update.
- Android 0.1.2 media volume 30/30, speaker route active, saved sound=true. AudioTrack logs show occasional nonzero PCM; this does not establish audible output. No Godot audio script error identified.
- Actual 0.1.3 listening requested from user and pending. Next work remains diagnosing listening and sustained performance before chapter expansion.
- `git diff --check`: clean.

## Dialogue trace
- User: "Still silent" after clearer 0.1.2 control.
- Codex explained output investigation, added direct preview and modest gain, and asked whether Test sound is audible. No audible success claimed.

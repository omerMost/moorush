# ADR 0007 — Precompute the prototype’s synthesized sounds

**Status:** Provisional implementation choice, pending phone listening check
**Date:** 2026-10-07
**Supersedes:** None

## Context
Chapter 1 still lacks the HTML prototype’s short synth cues. Smoothness is now confirmed on Android; generating audio samples during gameplay would risk new spikes.

## Decision
`MooAudio` creates six 44.1kHz mono PCM clips once at startup from the prototype’s tone frequencies, envelopes and sequence timing. Reuse eight AudioStreamPlayer voices; rate-limit picks/drops to 70ms and other cues to 40ms. Gate uses the prototype stage jingle and suppresses the simultaneous unlock jingle. Unknown events are ignored. Muting stops active voices and blocks new playback.

Sound preference lives in `user://moo-audio-settings.json`, outside the three game slots, with a menu toggle. Loading reads settings without writing them. Font bundling follows the already-approved Baloo 2 backlog decision; include the original OFL license and use weight 800, with OS emoji fallback.

## Alternatives
- Generate or stream waveforms continuously: adds work during play and underrun risk.
- Commit synthesized WAV files: simple but duplicates the source tone definitions into binary outputs.
- Add music or replace the tones: changes the port’s scope.

## Consequences
Startup owns synthesis; gameplay only schedules cached clips. Polyphony/memory are bounded. Headless tests validate waveform duration/energy, muting/rate limits/persistence and drain playing clips before teardown. Phone tap/persistence is verified; poor control contrast/state was improved after the user reported a mute/listening problem. Actual audible phone output remains unresolved; automated sample checks do not establish listening quality.

## Phone follow-up
User reported "Still silent" despite sound=true, speaker routing, full media volume and nonzero app PCM in Android logs. Add a menu Test sound cue, disabled while muted, and +6dB voice gain (sample peaks stay below full scale). These are provisional listening aids; the device root cause remains unproven. Enabling sound plays a confirmation coin cue.

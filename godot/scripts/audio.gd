class_name MooAudio
extends Node
## Chapter 1's tiny synth, baked once rather than generated during gameplay.
## Settings are separate from save slots, so deleting a game retains sound preference.

const SAMPLE_RATE := 44100
const VOICES := 8
const SETTINGS_PATH := "user://moo-audio-settings.json"
const NOTES := {
	"pick": [[880.0, 0.05]],
	"drop": [[520.0, 0.05]],
	"coin": [[988.0, 0.06], [1319.0, 0.09]],
	"warn": [[220.0, 0.12]],
	"unlock": [[523.0, 0.08], [659.0, 0.08], [784.0, 0.08], [1047.0, 0.16]],
	"gate": [[523.0, 0.12], [659.0, 0.12], [784.0, 0.12], [1047.0, 0.3]],
}

var enabled := true
var settings_path := SETTINGS_PATH
var clips: Dictionary = {}
var played_count := 0
var _players: Array[AudioStreamPlayer] = []
var _last_play: Dictionary = {}


func _ready() -> void:
	_read_settings()
	for kind in NOTES:
		clips[kind] = make_clip(kind)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.max_polyphony = 1
		add_child(player)
		_players.append(player)


func stop_all() -> void:
	for player in _players:
		player.stop()
		player.stream = null

func _exit_tree() -> void:
	stop_all()

func consume(events: Array) -> void:
	# Finishing the gate also emits unlock. The stage jingle owns that moment.
	var has_gate := events.any(func(event): return event is Dictionary and event.get("kind", "") == "gate")
	for event in events:
		if not event is Dictionary:
			continue
		var kind := str(event.get("kind", ""))
		if kind == "unlock" and has_gate:
			continue
		play(kind)


func play(kind: String) -> bool:
	if not enabled or not clips.has(kind):
		return false
	var now := Time.get_ticks_msec()
	var interval := 70 if kind in ["pick", "drop"] else 40
	if _last_play.has(kind) and now - int(_last_play[kind]) < interval:
		return false
	for player in _players:
		if not player.playing:
			player.stream = clips[kind]
			player.play()
			_last_play[kind] = now
			played_count += 1
			return true
	# A burst cannot allocate extra voices or interrupt an existing jingle.
	return false


func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	if not enabled:
		stop_all()
	_last_play.clear()
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"sound": enabled}))


func _read_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		return
	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("sound") is bool:
		enabled = parsed.sound


static func make_clip(kind: String) -> AudioStreamWAV:
	if not NOTES.has(kind):
		return null
	var notes: Array = NOTES[kind]
	var duration := 0.0
	var note_start := 0.0
	for note in notes:
		duration = maxf(duration, note_start + float(note[1]) + 0.02)
		note_start += float(note[1]) * 0.9
	var count := ceili(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	note_start = 0.0
	for note in notes:
		var frequency := float(note[0])
		var length := float(note[1])
		var first := int(note_start * SAMPLE_RATE)
		var last := mini(count, ceili((note_start + length + 0.02) * SAMPLE_RATE))
		for i in range(first, last):
			var t := float(i) / SAMPLE_RATE - note_start
			if t < 0.0:
				continue
			var phase := TAU * frequency * t
			var wave := (1.0 if sin(phase) >= 0.0 else -1.0) if kind == "warn" else 2.0 / PI * asin(sin(phase))
			# Same exponential 10ms attack/decay as the HTML Web Audio effects.
			var gain := 0.0001
			if t < 0.01:
				gain *= pow(1800.0, t / 0.01)
			elif t < length:
				gain = 0.18 * pow(0.0001 / 0.18, (t - 0.01) / (length - 0.01))
			else:
				gain *= maxf(0.0, 1.0 - (t - length) / 0.02)
			samples[i] += wave * gain
		note_start += length * 0.9
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for i in count:
		pcm.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = SAMPLE_RATE
	clip.stereo = false
	clip.data = pcm
	return clip

extends SceneTree
var ok := true

func expect(value: bool, description: String) -> void:
	ok = ok and value
	print("  %s %s" % ["ok" if value else "BAD", description])

func _initialize() -> void:
	create_timer(10.0).timeout.connect(func():
		print("FAIL asynchronous test timed out")
		quit(1))
	run.call_deferred()

func run() -> void:
	var path := "user://test-audio-settings.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var audio := MooAudio.new()
	audio.settings_path = path
	root.add_child(audio)
	expect(audio.enabled and not FileAccess.file_exists(path), "startup defaults enabled without writing settings")
	for kind in ["pick", "drop", "coin", "warn", "unlock", "gate"]:
		var clip: AudioStreamWAV = audio.clips[kind]
		var peak := 0.0
		var energy := 0.0
		for i in range(0, clip.data.size(), 2):
			var v := clip.data.decode_s16(i) / 32768.0
			peak = maxf(peak, absf(v)); energy += v * v
		var rms := sqrt(energy / (clip.data.size() / 2))
		expect(clip.mix_rate == 44100 and not clip.stereo and clip.get_length() > 0.05 and clip.get_length() < 0.7 and peak > 0.1 and peak < 0.25 and rms > 0.003, "%s audible, bounded, mono 44.1kHz clip" % kind)
	expect(audio.play("pick") and not audio.play("pick"), "repeated harvest is rate limited")
	expect(not audio.play("unknown"), "unknown event is ignored")
	await create_timer(0.1).timeout
	audio.set_enabled(false)
	var before := audio.played_count
	audio.consume([{"kind": "coin"}, {"kind": "gate"}])
	expect(audio.played_count == before and audio._players.all(func(p): return not p.playing), "muting stops voices and blocks queued events")
	var restored := MooAudio.new()
	restored.settings_path = path
	root.add_child(restored)
	expect(not restored.enabled, "muted setting survives reconstruction")
	audio.set_enabled(true)
	before = audio.played_count
	audio.consume([{"kind": "unlock"}, {"kind": "gate"}])
	expect(audio.played_count == before + 1, "gate emits one celebration without duplicate upgrade jingle")
	for i in 30: audio.consume([{"kind": "coin"}, {"kind": "drop"}, {"kind": "warn"}])
	expect(audio._players.size() == 8 and audio.get_child_count() == 8, "burst keeps fixed eight-voice pool")
	await create_timer(0.75).timeout
	audio.stop_all(); restored.stop_all()
	await create_timer(0.15).timeout
	audio.free(); restored.free()
	await process_frame
	DirAccess.remove_absolute(path)
	print(("PASS" if ok else "FAIL") + " audio")
	quit(0 if ok else 1)

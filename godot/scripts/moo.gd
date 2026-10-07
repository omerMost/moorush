extends Node
## Autoload `Moo`: owns the running MooSim and is the test API for bots
## (the Godot twin of the prototype's window.__moo, L2231).
## Headless tests may also build their own MooSim directly (tests/).

var sim: MooSim
var audio: MooAudio
var perf_times: Array[float] = []
var perf_elapsed := 0.0
var perf_draw_us := 0.0

var paused := true  # true while the slot menu is open
var app_focused := true
var app_paused := false
var suspended: bool:
	get: return not app_focused or app_paused

signal suspension_changed(is_suspended: bool)

signal slot_started(i: int)

func _ready() -> void:
	sim = MooSim.new()
	audio = MooAudio.new()
	add_child(audio)

func _exit_tree() -> void:
	if sim:
		sim.dispose()

# Debug Android measurements only; no HUD or save changes.
func _process(delta: float) -> void:
	if not OS.is_debug_build() or OS.get_name() != "Android":
		return
	if paused or suspended or delta > 0.5:
		perf_times.clear(); perf_elapsed = 0.0; perf_draw_us = 0.0
		return
	perf_times.append(delta * 1000.0)
	perf_elapsed += delta
	var world = get_tree().root.find_child("World", true, false)
	if world:
		perf_draw_us += world.draw_cpu_us
	if perf_elapsed >= 5.0:
		perf_times.sort()
		print("MOO_PERF fps=%.1f frame_p95_ms=%.2f draw_cpu_ms=%.2f" % [perf_times.size() / perf_elapsed, perf_times[int(perf_times.size() * 0.95)], perf_draw_us / perf_times.size() / 1000.0])
		perf_times.clear(); perf_elapsed = 0.0; perf_draw_us = 0.0

# ---- test API ----
func state() -> Dictionary: return sim.state_summary()
func input(x: float, y: float) -> void: sim.test_in = Vector2(x, y)
func step(dt: float, n: int = 1) -> void:
	for i in n:
		sim.update(dt)
func snapshot() -> Dictionary: return sim.snapshot()
func apply_state(d: Dictionary) -> void: sim.apply_state(d)
func guide_target(): return sim.guide_target()
func find_path(ax: float, ay: float, bx: float, by: float): return sim.find_path(ax, ay, bx, by)
func pads() -> Array: return sim.pads
func mods() -> Array: return sim.mods
func helpers() -> Array: return sim.helpers
func set_no_clip(v: bool) -> void: sim.no_clip = v

func start_slot(i: int) -> void:
	var loaded := sim.start_slot(i)
	if loaded:
		audio.play("coin")
	if not loaded:
		sim.toast(sim.stage.intro, 5.0)
	paused = false
	slot_started.emit(i)

func open_menu() -> void:
	if sim.cur_slot and not paused:
		sim.save(true)
	paused = true
	sim.test_in = Vector2.ZERO
	sim.move_in = Vector2.ZERO
	sim.clear_combat_input()

## OS focus and pause events can arrive in either order; resume after both clear.
func set_lifecycle(focused: bool, stopped: bool) -> void:
	var was_suspended := suspended
	app_focused = focused
	app_paused = stopped
	if suspended:
		if sim:
			sim.test_in = Vector2.ZERO
			sim.move_in = Vector2.ZERO
			sim.clear_combat_input()
			sim.events.clear()
		if audio: audio.stop_all()
		if not was_suspended and sim and sim.cur_slot:
			sim.save(true)
	if was_suspended != suspended:
		suspension_changed.emit(suspended)
		if OS.is_debug_build() and OS.get_name() == "Android":
			print("MOO_LIFECYCLE suspended=%s menu_paused=%s slot=%d" % [suspended, paused, sim.cur_slot if sim else 0])

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			set_lifecycle(false, app_paused)
		NOTIFICATION_APPLICATION_PAUSED:
			set_lifecycle(app_focused, true)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			set_lifecycle(true, app_paused)
		NOTIFICATION_APPLICATION_RESUMED:
			set_lifecycle(app_focused, false)
		NOTIFICATION_WM_CLOSE_REQUEST:
			if sim and sim.cur_slot: sim.save(true)

# ---- demo / screenshot mode: godot --path godot -- --demo=SECONDS --shot=PATH ----
## Fast-forwards a fresh game in a throwaway save dir with the arrow bot, then
## (optionally) saves a PNG of the real rendered frame and quits.
func _enter_tree() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("profile"):
		_run_profile.call_deferred(int(args.profile))
	if args.has("demo"):
		_run_demo.call_deferred(float(args.demo), args.get("shot", ""))

func _run_demo(secs: float, shot: String) -> void:
	sim.rng.seed = 1
	sim.save_dir = "user://demo"
	sim.delete_slot(1)
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.start(1)
	else:
		start_slot(1)
	sim.toasts.clear()
	var bot := MooBot.new(sim)
	var dt := 1.0 / 30.0
	while sim.T < secs:
		bot.tick(dt)
		sim.update(dt)
	sim.test_in = Vector2.ZERO
	if shot != "":
		for i in 30:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot)
		print("screenshot saved: ", shot, " at game time ", sim.T)
		get_tree().quit()

# Display-dependent deterministic draw benchmark; use --demo=240 --profile=300.
func _run_profile(frames: int) -> void:
	var samples: Array[float] = []
	for i in 30:
		await get_tree().process_frame
	var world = get_tree().root.find_child("World", true, false)
	for i in frames:
		await RenderingServer.frame_post_draw
		samples.append(world.draw_cpu_us / 1000.0)
	var total := 0.0
	for v in samples: total += v
	samples.sort()
	print("MOO_PROFILE frames=%d draw_mean_ms=%.3f draw_p95_ms=%.3f" % [frames, total / frames, samples[int(frames * 0.95)]])
	get_tree().quit()

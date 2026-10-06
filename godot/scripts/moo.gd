extends Node
## Autoload `Moo`: owns the running MooSim and is the test API for bots
## (the Godot twin of the prototype's window.__moo, L2231).
## Headless tests may also build their own MooSim directly (tests/).

var sim: MooSim
var paused := true  # true while the slot menu is open

signal slot_started(i: int)

func _ready() -> void:
	sim = MooSim.new()

func _exit_tree() -> void:
	if sim:
		sim.dispose()

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
	if not loaded:
		sim.toast(MooData.stage0().intro, 5.0)
	paused = false
	slot_started.emit(i)

func open_menu() -> void:
	if sim.cur_slot and not paused:
		sim.save(true)
	paused = true
	sim.test_in = Vector2.ZERO
	sim.move_in = Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if sim and sim.cur_slot:
			sim.save(true)

# ---- demo / screenshot mode: godot --path godot -- --demo=SECONDS --shot=PATH ----
## Fast-forwards a fresh game in a throwaway save dir with the arrow bot, then
## (optionally) saves a PNG of the real rendered frame and quits.
func _enter_tree() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("demo"):
		_run_demo.call_deferred(float(args.demo), args.get("shot", ""))

func _run_demo(secs: float, shot: String) -> void:
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

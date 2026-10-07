extends SceneTree
## Real autoload/scene lifecycle: persistent suspension, independent menu/focus state.
var ok := true
var save_dir := "user://test_lifecycle_%d" % OS.get_process_id()

func expect(value: bool, label: String) -> void:
	ok = value and ok
	print("  %s %s" % ["ok" if value else "BAD", label])

func stable(data: Dictionary) -> Dictionary:
	var result: Dictionary = JSON.parse_string(JSON.stringify(data))
	result.erase("t")
	return result

func notify_app(what: int) -> void:
	root.propagate_notification(what)

func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		print("FAIL app_lifecycle timed out")
		quit(1))
	run.call_deferred()

func run() -> void:
	var moo = root.get_node("Moo")
	moo.sim.save_dir = save_dir
	moo.audio.settings_path = save_dir + "/audio.json"
	var original_sound: bool = moo.audio.enabled
	moo.audio.enabled = true
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var world = main.get_node("World")
	var hud = root.find_child("HUD",true,false)
	# Explicit stepping isolates lifecycle assertions from test-runner frame timing.
	world.set_process(false)
	hud.set_process(false)
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	notify_app(Node.NOTIFICATION_APPLICATION_RESUMED)
	hud.start(1)
	moo.audio.play("gate")
	await create_timer(0.1).timeout
	var playing_before := false
	for voice in moo.audio._players: playing_before = playing_before or voice.playing
	expect(playing_before, "real sound voice is active before suspension")
	var sim: MooSim = moo.sim
	sim.S.money = 137
	sim.pads[0].paid = 23
	sim.player.stack = {"type":"corn","n":2,"inc":0}
	sim.stack_fly("corn",{"x":sim.player.x,"y":sim.player.y},sim.player)
	var tray = sim.mod_by("B",0).tray
	tray.n = 3; tray.inc = 0
	tray.item_slots = [0,2,4]; tray.arriving_slots = []
	var slot: int = sim.reserve_slot(tray)
	var flight: Dictionary = sim.fly("milk",0,0,func(): return sim.pile_pos(tray.rect,slot,tray.type),tray,0.5)
	flight.slot = slot
	var settled := sim.snapshot()
	var expected := stable(settled)
	expect(settled.hold == ["corn",2] and settled.bx["0B"].t == 3 and settled.bx["0B"].tp == [0,2,4], "suspension snapshot follows settled-only incoming goods contract")
	var touch := InputEventScreenTouch.new()
	touch.index = 1; touch.pressed = true; touch.position = Vector2(100,750)
	hud._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 1; drag.position = Vector2(145,750)
	hud._input(drag)
	hud._process(0.0)
	sim.test_in = Vector2.UP
	expect(hud.joy != null and sim.move_in != Vector2.ZERO, "real HUD joystick and test input are active before Home")
	sim.events.append({"kind":"pick"})
	sim.events.append({"kind":"drop"})
	var sounds_before: int = moo.audio.played_count
	var time_before: float = sim.T
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(sim.events.is_empty(), "Home discards queued gameplay cues before stopping")
	expect(moo.get("suspended") == true and not moo.paused, "Home suspension is separate from open-menu pause")
	expect(hud.joy == null and sim.move_in == Vector2.ZERO and sim.test_in == Vector2.ZERO, "Home immediately clears joystick and both movement inputs")
	var all_stopped := true
	for voice in moo.audio._players: all_stopped = all_stopped and not voice.playing
	expect(all_stopped, "Home immediately stops real audio voices")
	var disk: Dictionary = sim.read_slot(1)
	expect(stable(disk) == expected, "Home writes wallet, partial payment, held goods and sparse tray state")
	var file_before: String = FileAccess.get_file_as_string(sim.slot_path(1))
	await create_timer(0.02).timeout
	notify_app(Node.NOTIFICATION_APPLICATION_PAUSED)
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	notify_app(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(FileAccess.get_file_as_string(sim.slot_path(1)) == file_before, "repeated pause/focus-out notifications do not rewrite suspension save")
	hud._input(touch)
	hud._process(0.0)
	for i in range(10): world._process(0.05)
	expect(hud.joy == null and sim.move_in == Vector2.ZERO and sim.T == time_before, "background ignores touch and does not advance simulation")
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	world._process(0.05)
	expect(moo.get("suspended") == true and sim.T == time_before, "focus returning alone does not resume an application still paused")
	notify_app(Node.NOTIFICATION_APPLICATION_RESUMED)
	expect(moo.get("suspended") == false and not moo.paused and not hud.menu.visible, "both resume flags clear and active game resumes automatically")
	hud._input(touch)
	hud._input(drag)
	hud._process(0.0)
	expect(hud.joy != null and sim.move_in.is_equal_approx(Vector2.RIGHT), "touch joystick works again after suspension clears")
	var release: InputEventScreenTouch = touch.duplicate()
	release.pressed = false
	hud._input(release)
	hud._process(0.0)
	expect(hud.joy == null and sim.move_in == Vector2.ZERO, "resumed joystick release stops movement")
	world._process(0.03)
	expect(moo.audio.played_count == sounds_before, "resume does not replay discarded pre-background sound effects")
	expect(is_equal_approx(sim.T,time_before + 0.03), "world advances normally after both lifecycle flags clear")
	# Reverse Android callback order: resumed arrives before focus-in.
	notify_app(Node.NOTIFICATION_APPLICATION_PAUSED)
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	time_before = sim.T
	notify_app(Node.NOTIFICATION_APPLICATION_RESUMED)
	world._process(0.05)
	expect(moo.get("suspended") == true and sim.T == time_before, "application-resumed alone waits for focus-in in reverse callback order")
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	expect(moo.get("suspended") == false and not moo.paused, "reverse callback order resumes active game")
	# Keep an already-open slot menu open through the same OS round trip.
	hud.show_menu()
	time_before = sim.T
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	notify_app(Node.NOTIFICATION_APPLICATION_PAUSED)
	notify_app(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	notify_app(Node.NOTIFICATION_APPLICATION_RESUMED)
	world._process(0.05)
	expect(moo.get("suspended") == false and moo.paused and hud.menu.visible and sim.T == time_before, "resume preserves an open menu without advancing the game")
	var cold := MooSim.new(81)
	cold.save_dir = save_dir
	expect(cold.start_slot(1), "fresh simulation cold-loads suspended game's actual slot file")
	expect(stable(cold.snapshot()) == expected, "cold load restores settled inventory, sparse slots, wallet and partial upgrades")
	cold.dispose()
	sim.delete_slot(1)
	moo.audio.stop_all()
	moo.audio.enabled = original_sound
	if FileAccess.file_exists(moo.audio.settings_path): DirAccess.remove_absolute(moo.audio.settings_path)
	DirAccess.remove_absolute(save_dir)
	expect(moo.get("suspended") == false and moo.paused, "cleanup leaves lifecycle flags resumed and game menu paused")
	main.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print(("PASS" if ok else "FAIL") + " app_lifecycle")
	quit(0 if ok else 1)

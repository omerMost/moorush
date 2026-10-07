extends SceneTree
## Exercise touch input through the running scene at phone pixel sizes.
func _initialize() -> void:
	create_timer(10.0).timeout.connect(func():
		print("FAIL asynchronous test timed out")
		quit(1))
	run.call_deferred()

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	moo.audio.settings_path = "user://test-touch-audio-settings.json"
	moo.sim.save_dir = "user://test_touch_hud"
	moo.sim.delete_slot(1)
	var hud = root.find_child("HUD", true, false)
	var ok: bool = hud.process_priority < main.get_node("World").process_priority
	Paint.fonts()
	ok = ok and Paint.font.base_font.resource_path == "res://assets/fonts/Baloo2-Variable.ttf"
	ok = ok and Paint.font.has_char("M".unicode_at(0))
	print("  bundled Baloo 2 loaded: %s" % (Paint.font.base_font is FontFile))
	print("  fresh HUD input precedes simulation: %s" % ok)
	for pixels in [Vector2i(1080, 1920), Vector2i(1440, 2560)]:
		root.size = pixels
		await process_frame
		await process_frame
		hud.start(1)
		await process_frame
		ok = ok and hud.size.is_equal_approx(Vector2(540, 960))
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = Vector2(100, 750)
		touch.pressed = true
		hud._input(touch)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = Vector2(145, 750)
		hud._input(drag)
		hud._process(0.0)
		ok = ok and moo.sim.move_in.is_equal_approx(Vector2.RIGHT)
		touch.pressed = false
		hud._input(touch)
		hud._process(0.0)
		ok = ok and moo.sim.move_in == Vector2.ZERO
		# Two live IDs: movement release must not end right-stick fire.
		moo.sim.S.gun = 1
		touch.index = 0; touch.position = Vector2(100,750); touch.pressed = true; hud._input(touch)
		touch = touch.duplicate(); touch.index = 1; touch.position = Vector2(420,750); hud._input(touch)
		drag.index = 0; drag.position = Vector2(145,750); hud._input(drag)
		drag = drag.duplicate(); drag.index = 1; drag.position = Vector2(420,795); hud._input(drag)
		hud._process(0)
		ok = ok and moo.sim.move_in == Vector2.RIGHT and moo.sim.aim_in == Vector2.DOWN and moo.sim.fire_in
		touch.index = 0; touch.pressed = false; hud._input(touch); hud._process(0)
		ok = ok and moo.sim.move_in == Vector2.ZERO and moo.sim.fire_in
		touch.index = 1; hud._input(touch); hud._process(0)
		ok = ok and not moo.sim.fire_in and not moo.sim.quick_shot
		touch.position = Vector2(420,750); touch.pressed = true; hud._input(touch)
		touch = touch.duplicate(); touch.pressed = false; hud._input(touch)
		ok = ok and moo.sim.quick_shot
		moo.open_menu()
		ok = ok and not moo.sim.quick_shot and not moo.sim.fire_in
		hud.controls.clear()
		moo.paused = false
		hud._process(0)
		# Desktop click routes through the actual viewport; Dash never creates a stick.
		var dash_tap := InputEventMouseButton.new()
		dash_tap.button_index = MOUSE_BUTTON_LEFT
		dash_tap.position = hud.controls.dash_btn.get_global_rect().get_center()
		dash_tap.pressed = true; root.push_input(dash_tap,true)
		dash_tap = dash_tap.duplicate(); dash_tap.pressed = false; root.push_input(dash_tap,true)
		ok = ok and moo.sim.dash_request and hud.joy == null
		moo.sim.clear_combat_input()
		dash_tap.position = Vector2(450,400); dash_tap.pressed = true; root.push_input(dash_tap,true); hud._process(0)
		ok = ok and moo.sim.fire_in and moo.sim.aim_in.length() > 0.99 and hud.controls.aim == null and hud.joy == null
		var emulated := dash_tap.duplicate()
		emulated.device = InputEvent.DEVICE_ID_EMULATION; emulated.pressed = false; hud._input(emulated)
		ok = ok and moo.sim.fire_in
		# Release location must never retain an existing movement/aim/fire ID.
		dash_tap.position = hud.controls.dash_btn.get_global_rect().get_center(); dash_tap.pressed = false
		hud._input(dash_tap); hud._process(0)
		ok = ok and not moo.sim.fire_in
		for endpoint in [hud.controls.dash_btn.get_global_rect().get_center(),hud.menu_btn.get_global_rect().get_center()]:
			touch.index = 0; touch.position = Vector2(100,750); touch.pressed = true; hud._input(touch)
			drag.index = 0; drag.position = Vector2(145,750); hud._input(drag)
			touch = touch.duplicate(); touch.pressed = false; touch.position = endpoint; hud._input(touch)
			ok = ok and hud.joy == null
			touch.index = 1; touch.position = Vector2(420,750); touch.pressed = true; hud._input(touch)
			drag.index = 1; drag.position = Vector2(420,795); hud._input(drag)
			touch = touch.duplicate(); touch.pressed = false; touch.position = endpoint; hud._input(touch)
			ok = ok and hud.controls.aim == null
		moo.set_lifecycle(false,false); hud._process(0)
		ok = ok and not moo.sim.fire_in and hud.controls.aim == null and not moo.sim.dash_request
		moo.set_lifecycle(true,false)
		print("  dual touch IDs, independent release, quick tap/menu reset: %s" % ok)
		hud.show_menu()
		await process_frame
		ok = ok and moo.paused and hud.menu.visible and hud.menu.size.x <= hud.size.x and hud.menu.size.y <= hud.size.y
		var sound = hud.menu_box.find_child("SoundToggle", false, false)
		var original: bool = moo.audio.enabled
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.position = sound.get_global_rect().get_center()
		tap.pressed = true
		root.push_input(tap, true)
		tap = tap.duplicate()
		tap.pressed = false
		root.push_input(tap, true)
		await process_frame
		var clicked: bool = moo.audio.enabled == not original
		print("  menu pointer click toggles sound: %s" % clicked)
		ok = ok and clicked
		sound.button_pressed = original
		var preview = hud.menu_box.find_child("SoundPreview", false, false)
		ok = ok and preview.disabled == not original
		if original:
			var before: int = moo.audio.played_count
			tap = tap.duplicate()
			tap.position = preview.get_global_rect().get_center()
			tap.pressed = true
			root.push_input(tap, true)
			tap = tap.duplicate()
			tap.pressed = false
			root.push_input(tap, true)
			ok = ok and moo.audio.played_count == before + 1
			print("  preview pointer click schedules celebration: %s" % (moo.audio.played_count == before + 1))
		print("  phone %s logical HUD=%s touch/menu checked" % [pixels, hud.size])
	# Migrated bakery owner sees all three travel controls; exercise pointer routing.
	moo.sim.apply_state({"ver": 9, "ch": 1, "done": true})
	hud.show_menu()
	await process_frame
	await process_frame
	var row = hud.menu_box.find_child("TravelRow", false, false)
	ok = ok and row != null and row.get_child_count() == 3
	ok = ok and hud.menu.size.x <= hud.size.x and hud.menu.size.y <= hud.size.y
	if row != null:
		var travel = row.find_child("Travel2", false, false)
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.position = travel.get_global_rect().get_center()
		tap.pressed = true
		root.push_input(tap, true)
		tap = tap.duplicate()
		tap.pressed = false
		root.push_input(tap, true)
		ok = ok and not moo.paused and not hud.menu.visible and moo.sim.player.x > 3000
		print("  bakery travel pointer and three-district menu checked: %s" % ok)
	moo.sim.delete_slot(1)
	if FileAccess.file_exists(moo.audio.settings_path): DirAccess.remove_absolute(moo.audio.settings_path)
	await create_timer(0.75).timeout
	moo.audio.stop_all()
	print(("PASS" if ok else "FAIL") + " touch_hud")
	quit(0 if ok else 1)

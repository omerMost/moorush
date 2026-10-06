extends SceneTree
## Exercise touch input through the running scene at phone pixel sizes.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	moo.sim.save_dir = "user://test_touch_hud"
	moo.sim.delete_slot(1)
	var hud = root.find_child("HUD", true, false)
	var ok: bool = hud.process_priority < main.get_node("World").process_priority
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
		hud.show_menu()
		await process_frame
		ok = ok and moo.paused and hud.menu.visible and hud.menu.size.x <= hud.size.x
		print("  phone %s logical HUD=%s touch/menu checked" % [pixels, hud.size])
	moo.sim.delete_slot(1)
	print(("PASS" if ok else "FAIL") + " touch_hud")
	quit(0 if ok else 1)

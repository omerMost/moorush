extends SceneTree
## Render the real dairy bot in isolated storage, including menu travel.
func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	run.call_deferred()

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	moo.sim.save_dir = "user://chapter2-render-%d" % Time.get_ticks_usec()
	moo.sim.autosave = false
	var hud = main.get_node("UI/HUD")
	hud.start(1)
	var bot := MooBot.new(moo.sim)
	var output := ProjectSettings.globalize_path("res://../build")
	DirAccess.make_dir_recursive_absolute(output)
	while moo.sim.T < 1000.0 and moo.sim.S.ch < 1:
		for i in 30:
			bot.tick(1.0 / 30.0)
			moo.sim.update(1.0 / 30.0)
		await process_frame
	if moo.sim.S.ch != 1:
		print("FAIL windowed_chapter2: dairy not reached")
		moo.sim.dispose()
		quit(1)
		return
	var press = moo.sim.mod_by("C", 1)
	var cheese_shop = moo.sim.mod_by("D", 1)
	while moo.sim.T < 2000.0 and (cheese_shop.sold <= 0 or (MooSim.avail(press.tray) <= 0 and MooSim.avail(cheese_shop.box) <= 0)):
		for i in 30:
			bot.tick(1.0 / 30.0)
			moo.sim.update(1.0 / 30.0)
		await process_frame
	var stock: int = MooSim.avail(press.tray) + MooSim.avail(cheese_shop.box)
	var cheese_ok: bool = cheese_shop.sold > 0 and stock > 0
	print("  natural cheese stock=%d sold=%d time=%.1fs" % [stock, cheese_shop.sold, moo.sim.T])
	moo.sim.test_in = Vector2.ZERO
	moo.sim.cam_focus = {"x": press.pen.x + press.pen.w / 2, "y": press.pen.y + press.pen.h / 2 + 100, "t": 2.0}
	main.get_node("World").cam_snapped = false
	await capture(output.path_join("playtest-dairy.png"))
	moo.sim.cam_focus = {"x": cheese_shop.bench.x + cheese_shop.bench.w / 2, "y": cheese_shop.bench.y + cheese_shop.bench.h / 2, "t": 2.0}
	main.get_node("World").cam_snapped = false
	await capture(output.path_join("playtest-cheese-shop.png"))
	hud.show_menu()
	await process_frame
	await process_frame
	await capture(output.path_join("playtest-dairy-menu.png"))
	var row = hud.menu_box.find_child("TravelRow", false, false)
	var ok: bool = cheese_ok and row != null and row.get_child_count() == 2 and hud.menu.size.x <= hud.size.x and hud.menu.size.y <= hud.size.y
	if ok:
		row.get_child(0).pressed.emit()
		var farm = moo.sim.mod_by("A", 0)
		ok = moo.sim.player.x < 1000 and not moo.paused and not hud.menu.visible
		ok = ok and absf(moo.sim.player.x - (farm.rect.x + farm.rect.w / 2)) < 1
	print(("PASS" if ok else "FAIL") + " windowed_chapter2: dairy/menu/travel time=%.1fs" % moo.sim.T)
	moo.audio.stop_all()
	moo.sim.dispose()
	quit(0 if ok else 1)

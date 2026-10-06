extends SceneTree
## Optional rendered bakery bot: real purchases, production, sales and travel.
func _initialize() -> void:
	create_timer(120.0).timeout.connect(func():
		print("FAIL windowed_chapter3 timeout")
		quit(1))
	run.call_deferred()

func capture(main: Node, moo: Node, x: float, y: float, path: String) -> void:
	moo.sim.cam_focus = {"x": x, "y": y, "t": 2.0}
	main.get_node("World").cam_snapped = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	moo.sim.save_dir = "user://chapter3-render-%d" % Time.get_ticks_usec()
	moo.sim.autosave = false
	var hud = main.get_node("UI/HUD")
	hud.start(1)
	var bot := MooBot.new(moo.sim)
	var output := ProjectSettings.globalize_path("res://../build")
	DirAccess.make_dir_recursive_absolute(output)
	while moo.sim.T < 3500.0 and moo.sim.S.ch < 2:
		for i in 60:
			bot.tick(1.0 / 30.0)
			moo.sim.update(1.0 / 30.0)
		await process_frame
	if moo.sim.S.ch != 2:
		print("FAIL windowed_chapter3: bakery not reached")
		moo.sim.dispose()
		quit(1)
		return
	var ovens = moo.sim.mod_by("B", 2)
	var bread_shop = moo.sim.mod_by("C", 2)
	var orchard = moo.sim.mod_by("D", 2)
	var pie_ovens = moo.sim.mod_by("E", 2)
	var pie_shop = moo.sim.mod_by("F", 2)
	while moo.sim.T < 5000.0 and (bread_shop.sold <= 0 or pie_shop.sold <= 0 or MooSim.avail(ovens.tray) + MooSim.avail(bread_shop.box) <= 0 or MooSim.avail(pie_ovens.tray) + MooSim.avail(pie_shop.box) <= 0):
		for i in 60:
			bot.tick(1.0 / 30.0)
			moo.sim.update(1.0 / 30.0)
		await process_frame
	var bread_stock: int = MooSim.avail(ovens.tray) + MooSim.avail(bread_shop.box)
	var pie_stock: int = MooSim.avail(pie_ovens.tray) + MooSim.avail(pie_shop.box)
	var ok: bool = bread_stock > 0 and pie_stock > 0 and bread_shop.sold > 0 and pie_shop.sold > 0 and not orchard.locked
	print("  natural bakery bread=%d sold=%d pie=%d sold=%d time=%.1fs" % [bread_stock, bread_shop.sold, pie_stock, pie_shop.sold, moo.sim.T])
	moo.sim.test_in = Vector2.ZERO
	await capture(main, moo, ovens.pen.x + ovens.pen.w / 2, ovens.pen.y + ovens.pen.h / 2 + 100, output.path_join("playtest-bread.png"))
	await capture(main, moo, pie_ovens.pen.x + pie_ovens.pen.w / 2, pie_ovens.pen.y + pie_ovens.pen.h / 2 + 100, output.path_join("playtest-pie.png"))
	await capture(main, moo, orchard.rect.x + orchard.rect.w / 2, orchard.rect.y + orchard.rect.h / 2, output.path_join("playtest-orchard.png"))
	hud.show_menu()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("playtest-bakery-menu.png"))
	var row = hud.menu_box.find_child("TravelRow", false, false)
	ok = ok and row != null and row.get_child_count() == 3 and hud.menu.size.x <= hud.size.x and hud.menu.size.y <= hud.size.y
	if ok:
		row.get_child(0).pressed.emit()
		var farm = moo.sim.mod_by("A", 0)
		ok = not moo.paused and not hud.menu.visible and absf(moo.sim.player.x - (farm.rect.x + farm.rect.w / 2)) < 1
	print(("PASS" if ok else "FAIL") + " windowed_chapter3: bakery/menu/travel")
	moo.audio.stop_all()
	moo.sim.dispose()
	quit(0 if ok else 1)

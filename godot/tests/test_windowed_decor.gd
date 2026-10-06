extends SceneTree
## Optional visual review of natural revealed land and the cheese replacement.
class CheesePreview extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 540, 960), Paint.C("#fff8e7"))
		Paint.text(self, "Cheese silhouette", 270, 80, 30, Paint.C("#3a2412"))
		Paint.text(self, "Previous", 135, 175, 20, Paint.C("#3a2412"))
		Paint.text(self, "Updated", 395, 175, 20, Paint.C("#3a2412"))
		draw_set_transform(Vector2(135, 350), 0, Vector2(7, 7))
		Paint.poly(self, [Vector2(-10, -12), Vector2(10, -7), Vector2(10, 2), Vector2(-10, -3)], Paint.C("#e6a52b"))
		Paint.poly(self, [Vector2(-10, -12), Vector2(-1, -20), Vector2(10, -7)], Paint.C("#ffe47a"))
		Paint.poly(self, [Vector2(-10, -12), Vector2(10, -7), Vector2(10, -1), Vector2(-10, -6)], Paint.C("#f6c943"))
		for hole in [Vector2(-5, -8), Vector2(3, -6), Vector2(6, -2)]:
			Paint.ell(self, hole.x, hole.y, 1.8, 1.5, Paint.C("#c4861c"))
		Paint.ell(self, -1, -14, 2, 1.1, Paint.C("#dfb540"))
		draw_set_transform(Vector2.ZERO)
		Paint.item(self, "cheese", 395, 350, 7)
		Paint.text(self, "Actual cached item · stack", 270, 490, 20, Paint.C("#3a2412"))
		for i in 8:
			Paint.item(self, "cheese", 270, 760 - i * 25, 2)

func _initialize() -> void:
	create_timer(90.0).timeout.connect(func():
		print("FAIL windowed_decor timeout")
		quit(1))
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
	moo.sim.save_dir = "user://decor-render-%d" % Time.get_ticks_usec()
	moo.sim.autosave = false
	main.get_node("UI/HUD").start(1)
	var bot := MooBot.new(moo.sim)
	var land = null
	while moo.sim.T < 3500.0:
		for i in 60:
			bot.tick(1.0 / 30.0)
			moo.sim.update(1.0 / 30.0)
		await process_frame
		for cell in moo.sim.cells:
			if cell.on and cell.mod == null and cell.decor.any(func(d): return d.kind == "pond") and cell.decor.any(func(d): return d.kind == "tree"):
				land = cell
				break
		if land != null: break
	var output := ProjectSettings.globalize_path("res://../build")
	DirAccess.make_dir_recursive_absolute(output)
	var ok: bool = land != null
	if ok:
		moo.sim.test_in = Vector2.ZERO
		# Let the normal reveal animation finish in simulation time, independent of FPS.
		for i in 120: moo.sim.update(1.0 / 30.0)
		await process_frame
		moo.sim.cam_focus = {"x": land.x + land.w / 2, "y": land.y + land.h / 2, "t": 2.0}
		main.get_node("World").cam_snapped = false
		await capture(output.path_join("playtest-map-decor.png"))
		print("  naturally revealed tree/pond cell=%s time=%.1fs" % ["%d:%d:%d" % [land.d, land.c, land.r], moo.sim.T])
	main.get_node("UI/HUD").visible = false
	var preview := CheesePreview.new()
	root.add_child(preview)
	preview.z_index = 100
	await capture(output.path_join("playtest-cheese-comparison.png"))
	ok = ok and Paint.item_textures.has("cheese")
	print(("PASS" if ok else "FAIL") + " windowed_decor: trees/pond/cached cheese land=%s cached=%s time=%.1fs" % [land != null, Paint.item_textures.has("cheese"), moo.sim.T])
	moo.audio.stop_all()
	moo.sim.dispose()
	quit(0 if ok else 1)

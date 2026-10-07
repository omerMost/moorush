extends SceneTree
## Rendered clock/lighting acceptance through the real scene; run with a display.
var ok := true

func expect(value: bool, label: String) -> void:
	ok = value and ok
	print("  %s %s" % ["ok" if value else "BAD", label])

func _initialize() -> void:
	run.call_deferred()

func luminance(c: Color) -> float:
	return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	var world = main.get_node("World")
	var hud = main.get_node("UI/HUD")
	world.set_process(false)
	hud.set_process(false)
	moo.sim.autosave = false
	moo.sim.save_dir = "user://windowed-clock-%d" % OS.get_process_id()
	hud.start(1)
	var output := ProjectSettings.globalize_path("res://../build")
	DirAccess.make_dir_recursive_absolute(output)
	var captures := {}
	for fixture in [
		{"name":"day","day":1,"time":0.08,"cn":0},
		{"name":"evening","day":1,"time":0.6,"cn":0},
		{"name":"night","day":1,"time":0.8,"cn":1},
		{"name":"boss-night","day":3,"time":0.8,"cn":3},
		{"name":"dawn","day":2,"time":0.0,"cn":1}]:
		moo.sim.restore_clock(fixture)
		world._process(0.0)
		hud.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		captures[fixture.name] = capture
		capture.save_png(output.path_join("clock-%s.png" % fixture.name))
		expect(world.night_view.visible == (fixture.name != "day"), "%s lighting follows darkness curve" % fixture.name)
	var day: Image = captures.day
	var night: Image = captures.night
	var boss: Image = captures["boss-night"]
	var outside := Vector2i(8, 400)
	var player_screen: Vector2 = (Vector2(moo.sim.player.x, moo.sim.player.y - 30) - world.cam) * world.zoom
	var center := Vector2i(player_screen)
	var outside_ratio := luminance(night.get_pixelv(outside)) / maxf(0.01, luminance(day.get_pixelv(outside)))
	var center_ratio := luminance(night.get_pixelv(center)) / maxf(0.01, luminance(day.get_pixelv(center)))
	expect(outside_ratio < 0.75 and center_ratio > outside_ratio + 0.15, "shader darkens distant ground while preserving player's radial light")
	expect(boss.get_pixelv(outside).r > night.get_pixelv(outside).r and boss.get_pixelv(outside).g < night.get_pixelv(outside).g, "third-night tint is red instead of blue")
	expect(day.get_pixel(30,28).is_equal_approx(night.get_pixel(30,28)), "night shader leaves the HUD money pill untouched")
	expect(world.night_view.shade.get_shader_parameter("light_count") <= 24, "lighting has a fixed 24-light bound")
	moo.sim.dispose()
	print(("PASS" if ok else "FAIL") + " windowed_clock")
	quit(0 if ok else 1)

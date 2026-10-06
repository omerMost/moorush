extends SceneTree
## Rendered career smoke test. Run without --headless; output goes to build/.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	moo.sim.save_dir = "user://windowed-test-%d" % Time.get_ticks_usec()
	moo.sim.autosave = false
	var hud = main.get_node("UI/HUD")
	hud.start(1)
	var bot := MooBot.new(moo.sim)
	var output := ProjectSettings.globalize_path("res://../build")
	DirAccess.make_dir_recursive_absolute(output)
	var milestones := [90.0, 240.0]
	var next := 0
	while moo.sim.T < 900.0 and not moo.sim.S.done:
		for i in 15:
			bot.tick(1.0 / 30.0)
			moo.sim.update(1.0 / 30.0)
		await process_frame
		if next < milestones.size() and moo.sim.T >= milestones[next]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("playtest-%d.png" % int(milestones[next])))
			next += 1
	moo.sim.test_in = Vector2.ZERO
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("playtest-complete.png"))
	var ok: bool = moo.sim.S.done
	print(("PASS" if ok else "FAIL") + " windowed_chapter1: gate=%s time=%.1fs" % [moo.sim.S.done, moo.sim.T])
	moo.sim.dispose()
	quit(0 if ok else 1)

extends SceneTree
## Rendered five-heart HUD and a real-scene faint/retry callback.
var ok := true
func expect(value: bool, label: String) -> void:
	ok = ok and value
	print("  %s %s" % ["ok" if value else "BAD",label])
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	var world = main.get_node("World")
	var hud = main.get_node("UI/HUD")
	world.set_process(false); hud.set_process(false)
	moo.sim.autosave = false
	moo.sim.save_dir = "user://windowed-hearts-%d" % OS.get_process_id()
	hud.start(1)
	var sim: MooSim = moo.sim
	hud._process(0.0); world._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var full := root.get_texture().get_image()
	sim.S.hearts = 1
	hud._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var one := root.get_texture().get_image()
	var changed := 0
	for y in range(20,40):
		for x in range(int(hud.size.x-165),int(hud.size.x-64)):
			if not full.get_pixel(x,y).is_equal_approx(one.get_pixel(x,y)): changed += 1
	expect(changed > 200, "four depleted HUD hearts visibly change while one remains filled")
	expect(full.get_pixel(30,28).is_equal_approx(one.get_pixel(30,28)), "hearts do not cover the money pill")
	sim.S.money = 321; sim.S.day = 2; sim.S.time = 0.7; sim.S.cn = 2
	sim.S.hearts = 5
	sim.begin_night(); sim.capture_checkpoint("dusk")
	sim.S.hearts = 1
	sim.hurt_player("Karen")
	world._process(0.0)
	hud.joy = {"id":1,"s":Vector2(30,600),"p":Vector2(80,600)}
	hud._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	expect(hud.faint_card.visible and hud.faint_line.text.contains("Karen") and hud.retry_btn.text == "Retry from dusk", "rendered faint card identifies attacker and retry destination")
	expect(hud.joy == null and sim.move_in == Vector2.ZERO, "faint card clears touch movement")
	var rect: Rect2 = hud.faint_card.get_global_rect()
	expect(Rect2(Vector2.ZERO,hud.size).encloses(rect), "faint card fits portrait viewport")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/hearts-faint.png"))
	var sound_before: bool = moo.audio.enabled
	# An unfocused automated window is OS-suspended; prove the guard first.
	moo.set_lifecycle(false, false)
	hud.retry_btn.pressed.emit()
	expect(sim.faint != null, "suspended retry cannot advance simulation")
	moo.set_lifecycle(true, false)
	hud.retry_btn.pressed.emit()
	hud._process(0.0)
	expect(sim.faint == null and sim.S.hearts == 5 and sim.S.money == 321 and sim.S.day == 2 and sim.S.cn == 2 and not hud.faint_card.visible, "real HUD retry button restores checkpoint and closes card")
	expect(moo.audio.enabled == sound_before and not moo.paused, "retry preserves sound preference and independent menu state")
	sim.dispose()
	print(("PASS" if ok else "FAIL") + " windowed_hearts")
	quit(0 if ok else 1)

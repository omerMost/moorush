extends SceneTree
## Rendered A/B for ADR 0024 (needs a window; not part of headless check.sh):
## godot --path godot -s res://tests/test_windowed_shape_cache.gd
## The same frozen full chapter-3 farm frame is drawn with the original
## per-call polygon path (Paint.mesh_cache=false, no people culling) and with
## cached shape meshes + culling. Every pixel must match, at several views.
## Also reports the draw CPU of both paths on this machine.
var ok := true
var save_dir := "user://test_shape_cache_%d" % OS.get_process_id()

func expect(value: bool, label: String) -> void:
	ok = value and ok
	print("  %s %s" % ["ok" if value else "BAD", label])

func _initialize() -> void:
	create_timer(240.0).timeout.connect(func():
		print("FAIL shape_cache timed out")
		quit(1))
	run.call_deferred()

func grab(world, hud, frames: int) -> Array:
	var cpu := 0.0
	for i in frames:
		world.cam_snapped = false
		world._process(0.0)
		hud._process(0.0)
		await process_frame
		cpu += world.draw_cpu_us / 1000.0
	await RenderingServer.frame_post_draw
	return [root.get_viewport().get_texture().get_image(), cpu / frames]

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("FAIL shape_cache needs a rendered window")
		quit(1)
		return
	var moo = root.get_node("Moo")
	moo.sim.save_dir = save_dir
	moo.audio.settings_path = save_dir + "/audio.json"
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var world = main.get_node("World")
	var hud = root.find_child("HUD", true, false)
	world.set_process(false)
	hud.set_process(false)
	hud.start(1)
	var sim: MooSim = moo.sim
	sim.autosave = false
	sim.rng.seed = 9
	for p in sim.pads:
		p.paid = p.cost
		sim.apply_pad(p, true)
	sim.compute_reveal()
	sim.travel_to(2)
	for i in 30: await process_frame  # item textures bake
	# Step count, not sim.T: a night checkpoint restore can rewind T. The fight
	# bot plays so night zombies and the night overlay appear in the views.
	var bot := MooFightBot.new(sim)
	for i in 30 * 300:  # to evening/night of day 1
		bot.tick()
		sim.update(1.0 / 30.0)
	sim.test_in = Vector2.ZERO; sim.fire_in = false
	sim.toasts.clear()
	sim.events.clear()
	var old_ms := 0.0
	var new_ms := 0.0
	var views := 0
	for d in [2, 0]:
		for cell in [0, 4, 5, 7]:
			var o := MooSim.cell_xy(d, cell % 3, cell / 3)
			sim.player.x = o.x + MooSim.CW / 2; sim.player.y = o.y + 4
			Paint.mesh_cache = false; world.cull_people = false
			var a: Array = await grab(world, hud, 4)
			Paint.mesh_cache = true; world.cull_people = true
			var b: Array = await grab(world, hud, 4)  # seeds, promotes, then reuses meshes
			var ia: Image = a[0]
			var ib: Image = b[0]
			var diff := 0
			var worst := 0.0
			for y in ia.get_height():
				for x in ia.get_width():
					var ca := ia.get_pixel(x, y)
					var cb := ib.get_pixel(x, y)
					if ca != cb:
						diff += 1
						worst = maxf(worst, maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b)) * 255.0)
			# Translating on the GPU instead of in GDScript can round an edge
			# pixel differently; allow at most 0.002% of the frame.
			expect(diff <= 10, "district %d cell %d: %d of %d pixels differ, max channel %d (old draw %.2fms, cached %.2fms)" % [d, cell, diff, ia.get_width() * ia.get_height(), worst, a[1], b[1]])
			old_ms += a[1]; new_ms += b[1]; views += 1
	print("  mean draw CPU over %d views: %.2fms polygon path -> %.2fms cached meshes" % [views, old_ms / views, new_ms / views])
	expect(Paint.shape_meshes.size() > 0, "shape meshes are in use (%d cached)" % Paint.shape_meshes.size())
	print(("PASS" if ok else "FAIL") + " shape_cache")
	quit(0 if ok else 1)

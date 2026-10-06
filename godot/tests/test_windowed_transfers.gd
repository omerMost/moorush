extends SceneTree
## Rendered QA fixtures only: real transfer APIs, isolated storage, fixed camera.
class ContactSheet extends Node2D:
	var panels: Array = []
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 1340), Paint.C("#fff8e7"))
		Paint.text(self, "Nearest pickup · remaining slots stay put", 480, 30, 24, Paint.C("#3a2412"))
		Paint.text(self, "Toss · fixed mouth, arc, then shrink and fade", 480, 692, 24, Paint.C("#3a2412"))
		for i in panels.size():
			var row: int = int((i % 6) / 3)
			var col: int = i % 3
			var base: float = 63 if i < 6 else 726
			var x: float = 8 + col * 320
			var y: float = base + row * 307
			Paint.text(self, panels[i].label, x + 152, y, 17, Paint.C("#3a2412"))
			draw_texture_rect(panels[i].texture, Rect2(x, y + 18, 304, 253), false)

var panels: Array = []
var ok := true
var output: String

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		print("FAIL windowed_transfers timeout")
		quit(1))
	run.call_deferred()

func camera(world: Node2D, point: Vector2, zoom_value: float) -> void:
	world.zoom = zoom_value
	world.cam = point - Vector2(600, 500) / (2 * zoom_value)
	world.vis_rect = Rect2(world.cam - Vector2(60, 60), Vector2(600, 500) / zoom_value + Vector2(120, 120))
	world.transform = Transform2D(0.0, Vector2(zoom_value, zoom_value), 0.0, -world.cam * zoom_value)
	world.queue_redraw()

func capture(world: Node2D, label: String, name: String) -> void:
	world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	pixels.save_png(output.path_join(name + ".png"))
	panels.append({"label": label, "texture": ImageTexture.create_from_image(pixels)})

func advance(sim: MooSim, duration: float) -> void:
	var steps := maxi(1, int(ceil(duration / 0.01)))
	for i in steps:
		sim.act_t = 0.0 # Each step is < ACT_TICK; only explicit fixture actions.
		sim.update(duration / steps)

func run() -> void:
	root.size = Vector2i(600, 500)
	root.content_scale_size = Vector2i(600, 500)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	moo.sim.save_dir = "user://transfer-render-%d" % Time.get_ticks_usec()
	moo.sim.autosave = false
	var hud = main.get_node("UI/HUD")
	hud.start(1)
	moo.paused = true
	hud.visible = false
	var sim: MooSim = moo.sim
	var world = main.get_node("World")
	world.set_process(false)
	output = ProjectSettings.globalize_path("res://../build")
	DirAccess.make_dir_recursive_absolute(output)
	var tray = sim.mod_by("B", 0).tray
	var initial := [0, 5, 9, 14, 30, 36, 44]
	for side in 2:
		tray.n = initial.size(); tray.inc = 0
		tray.item_slots = initial.duplicate(); tray.arriving_slots = []
		sim.flyers.clear()
		sim.player.stack = {"type": null, "n": 0, "inc": 0}
		sim.player.x = tray.rect.x - 10 if side == 0 else tray.rect.x + tray.rect.w + 10
		sim.player.y = tray.rect.y + 42
		sim.player.face = 1 if side == 0 else -1
		camera(world, Vector2(tray.rect.x + tray.rect.w / 2, tray.rect.y + 22), 1.7)
		var label := "Left" if side == 0 else "Right"
		await capture(world, label + " · before", "transfer-pick-%d-before" % side)
		var expected := -1
		var distance := INF
		for slot in initial:
			var d := MooSim.dist(sim.pile_pos(tray.rect, slot, tray.type), sim.player)
			if d < distance: distance = d; expected = slot
		ok = sim.take(tray, sim.player) and ok
		ok = ok and not expected in tray.item_slots and tray.n == initial.size() - 1
		print("  %s pickup removed nearest slot=%d remaining=%s" % [label, expected, tray.item_slots])
		advance(sim, 0.12)
		await capture(world, label + " · halfway", "transfer-pick-%d-flight" % side)
		advance(sim, 0.13)
		ok = ok and sim.player.stack.inc == 0 and sim.player.stack.n == 1
		await capture(world, label + " · after", "transfer-pick-%d-after" % side)
	var bin = sim.mod_by("A", 0).bin
	sim.flyers.clear()
	sim.player.stack = {"type": "milk", "n": 1, "inc": 0}
	sim.player.x = bin.x + bin.w / 2.0
	sim.player.y = bin.y + bin.h + 15
	sim.player.face = 1
	camera(world, Vector2(bin.x + bin.w / 2.0, bin.y + 23), 3.5)
	sim.act()
	var tossing: Array = sim.flyers.filter(func(f): return f.get("kind", "") == "toss")
	ok = ok and tossing.size() == 1
	if tossing.size() == 1:
		var flight = tossing[0]
		var fixed = flight.to.call()
		ok = ok and fixed.x == bin.x + bin.w / 2 and fixed.y == bin.y + 8
		for ratio in [0.0, 0.25, 0.5, 0.75, 0.9, 1.0]:
			flight.t = flight.dur * ratio
			var pose = sim.flight_pose(flight)
			print("  Toss %.0f%% position=(%.1f,%.1f) scale=%.2f alpha=%.2f" % [ratio * 100, pose.x, pose.y, pose.scale, pose.alpha])
			await capture(world, "Toss %.0f%% · %.0fms" % [ratio * 100, ratio * 320], "transfer-toss-%03d" % int(ratio * 100))
	world.hide()
	root.size = Vector2i(960, 1340)
	root.content_scale_size = Vector2i(960, 1340)
	var sheet := ContactSheet.new()
	sheet.panels = panels
	root.add_child(sheet)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("transfer-contact-sheet.png"))
	moo.audio.stop_all()
	sim.dispose()
	print(("PASS" if ok else "FAIL") + " windowed_transfers: spatial pickups and Toss frames")
	quit(0 if ok else 1)

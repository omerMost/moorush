extends SceneTree
## Decision preview only. These three candidate shapes do not change game items.
class Options extends Node2D:
	var world_view: GDScript
	func shape(kind: int, x: float, y: float, scale_value: float = 1.0) -> void:
		draw_set_transform(Vector2(x, y), 0, Vector2(scale_value, scale_value))
		match kind:
			0:
				Paint.poly(self, [Vector2(-13, -8), Vector2(13, -6), Vector2(13, 5), Vector2(-13, 1)], Paint.C("#f4ba37"))
				Paint.poly(self, [Vector2(-13, -8), Vector2(6, -21), Vector2(13, -6)], Paint.C("#ffe57a"))
				Paint.poly(self, [Vector2(6, -21), Vector2(13, -6), Vector2(13, 5), Vector2(6, -10)], Paint.C("#e3a024"))
				for hole in [Vector3(-6, -4, 2.7), Vector3(4, -2, 2.3), Vector3(8, 1, 1.6)]:
					Paint.circ(self, hole.x, hole.y, hole.z, Paint.C("#cb8b21"))
				Paint.ell(self, 0, -13, 2.3, 1.6, Paint.C("#d7ad3e"))
			1:
				Paint.fill_rr(self, -13, -20, 26, 24, 3.5, Paint.C("#edb933"))
				Paint.fill_rr(self, -12, -20, 24, 22, 3, Paint.C("#ffe478"))
				Paint.stroke_rr(self, -12, -20, 24, 22, 3, Paint.C("#e3b544"), 0.8)
				for hole in [Vector3(-6, -14, 3), Vector3(5, -10, 3.5), Vector3(-3, -3, 2.5)]:
					Paint.circ(self, hole.x, hole.y, hole.z, Paint.C("#ceaa4e"))
					Paint.circ(self, hole.x + 0.5, hole.y + 0.5, hole.z * 0.75, Paint.C("#e8c265"))
				Paint.poly(self, [Vector2(7, 2), Vector2(12, -3), Vector2(12, 2)], Paint.C("#e3b544"))
			2:
				var top := [Vector2(0, -12)]
				for i in 33:
					var angle: float = deg_to_rad(40.0 + 320.0 * i / 32.0)
					top.append(Vector2(cos(angle) * 13, -12 + sin(angle) * 7))
				var bottom := []
				for point in top: bottom.append(point + Vector2(0, 7))
				Paint.poly(self, bottom, Paint.C("#dea22a"))
				var side := []
				for i in 17:
					var angle: float = deg_to_rad(40.0 + 140.0 * i / 16.0)
					side.append(Vector2(cos(angle) * 13, -12 + sin(angle) * 7))
				for i in range(16, -1, -1):
					var angle: float = deg_to_rad(40.0 + 140.0 * i / 16.0)
					side.append(Vector2(cos(angle) * 13, -5 + sin(angle) * 7))
				Paint.poly(self, side, Paint.C("#eeb73a"))
				Paint.poly(self, top, Paint.C("#ffe475"))
				Paint.poly(self, [Vector2(0, -12), Vector2(13, -12), Vector2(13, -5), Vector2(0, -5)], Paint.C("#f3cb5a"))
				Paint.poly(self, [Vector2(0, -12), top[1], top[1] + Vector2(0, 7), Vector2(0, -5)], Paint.C("#d89d2b"))
				for hole in [Vector2(-6, -13), Vector2(0, -16), Vector2(-3, -9)]:
					Paint.ell(self, hole.x, hole.y, 2, 1.3, Paint.C("#d5ad3c"))
		draw_set_transform(Vector2.ZERO)

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 900, 950), Paint.C("#fff8e7"))
		Paint.text(self, "Choose the cheese", 450, 42, 34, Paint.C("#3a2412"))
		Paint.text(self, "New light wooden holders · enlarged art and game-size stacks", 450, 84, 18, Paint.C("#78603d"))
		var names := ["Classic wedge", "Flat slice", "Cut wheel"]
		for kind in 3:
			var center: float = 150 + kind * 300
			Paint.text(self, String.chr(65 + kind), center, 143, 30, Paint.C("#8a602d"))
			shape(kind, center, 320, 7)
			Paint.text(self, names[kind], center, 365, 21, Paint.C("#3a2412"))
			world_view.tray_base(self, {"x": center - 110, "y": 423.0, "w": 220.0, "h": 76.0})
			for i in 24:
				shape(kind, center - 88 + (i % 8) * 24, 447 + int(i / 8) * 17)
			Paint.text(self, "Game-size stack", center, 545, 17, Paint.C("#78603d"))
			for i in 8: shape(kind, center, 692 - i * 14)
		Paint.text(self, "Milk holder · same wood", 450, 762, 22, Paint.C("#3a2412"))
		world_view.tray_base(self, {"x": 285.0, "y": 808.0, "w": 330.0, "h": 90.0})
		for i in 48:
			Paint.item(self, "milk", 302 + (i % 16) * 20, 835 + int(i / 16) * 22)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(900, 950)
	root.content_scale_size = Vector2i(900, 950)
	var options := Options.new()
	options.world_view = load("res://scripts/world_view.gd")
	if not options.world_view.can_instantiate():
		quit(1)
		return
	root.add_child(options)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/cheese-options.png"))
	print("PASS cheese_options: three preview-only shapes and production wooden holder")
	root.get_node("Moo").sim.dispose()
	quit()

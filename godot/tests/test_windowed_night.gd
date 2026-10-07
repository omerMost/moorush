extends SceneTree
## Real-scene rendering: Gary and all seven joke types remain visible under night lighting.
var ok := true

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
	moo.sim.save_dir = "user://windowed-night-%d" % OS.get_process_id()
	hud.start(1)
	var sim: MooSim = moo.sim
	sim.restore_clock({"day":2,"time":0.8,"cn":2})
	var actors := []
	var source = sim.mod_by("C",0)
	var types := ["gary","normal","karen","lactose","vault","influencer","flag","granny"]
	for i in types.size():
		var x: float = sim.player.x + (i%4-1.5)*100
		var y: float = sim.player.y - 100 + int(i/4)*170
		var z = sim._zombies.new_zombie(x,y,types[i],false,source,3)
		if z.type == "gary":
			z.shirt = "#c0504d"; z.pants = "#5b7aa5"; z.hair = "#e9c46a"; z.skin = "#d9b77a"
		actors.append(z)
	world._process(0.0); hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var empty := root.get_texture().get_image()
	sim.zombies = actors
	world._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var visible := root.get_texture().get_image()
	var output := ProjectSettings.globalize_path("res://../build/night-actors.png")
	visible.save_png(output)
	for z in actors:
		var position: Vector2 = (Vector2(z.x,z.y)-world.cam)*world.zoom
		var changes := 0
		for y in range(maxi(0,int(position.y-95*world.zoom)),mini(visible.get_height(),int(position.y))):
			for x in range(maxi(0,int(position.x-35*world.zoom)),mini(visible.get_width(),int(position.x+35*world.zoom))):
				if not empty.get_pixel(x,y).is_equal_approx(visible.get_pixel(x,y)): changes += 1
		var passes := changes > 30
		ok = passes and ok
		print("  %s %s visible under night shader (%d changed pixels)" % ["ok" if passes else "BAD",z.type,changes])
	ok = ok and empty.get_pixel(30,28).is_equal_approx(visible.get_pixel(30,28))
	sim.dispose()
	print(("PASS" if ok else "FAIL") + " windowed_night")
	quit(0 if ok else 1)

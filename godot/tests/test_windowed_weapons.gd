extends SceneTree
## Real portrait scene: naturally buy Milk squirter, shoot Gary, then render combat.
var ok := true
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var moo = root.get_node("Moo")
	var world = main.get_node("World")
	var hud = main.get_node("UI/HUD")
	world.set_process(false); hud.set_process(false)
	moo.sim.save_dir = "user://windowed-weapons-%d" % OS.get_process_id()
	moo.sim.autosave = false; hud.start(1)
	var s: MooSim = moo.sim
	var bot := MooBot.new(s)
	for i in 7200:
		bot.tick(1.0/30); s.update(1.0/30)
		if s.S.gun > 0 and s.S.tut.gary == 1: break
	ok = ok and s.S.gun == 1 and s.S.tut.gary == 1
	var g = s.zombies[0]
	# Fight driver travels via A*, keeping the naturally carried farm products.
	var route = s.find_path(s.player.x,s.player.y,g.x,g.y)
	var elapsed := 0.0
	while elapsed < 20 and s.S.tut.gary == 1:
		if route != null and not route.is_empty():
			while route.size() > 1 and MooSim.dist(s.player,route[0]) < 10: route.pop_front()
			s.test_in = (Vector2(route[0].x,route[0].y)-Vector2(s.player.x,s.player.y)).normalized()
		s.aim_in = (Vector2(g.x,g.y-20)-Vector2(s.player.x,s.player.y-30)).normalized()
		s.fire_in = MooSim.dist(g,s.player) < 230
		s.update(1.0/30); elapsed += 1.0/30
	ok = ok and s.S.tut.gary == 2 and s.S.hearts == 5
	print("  natural armory purchase and Gary shot in %.1fs: %s" % [elapsed,ok])
	s.dispose(); s.clear_combat_input(); s.test_in = Vector2.ZERO
	s.restore_clock({"day":2,"cn":2,"time":0.8})
	var r = s.mod_by("A",0).rect
	s.player.x = r.x+100; s.player.y = r.y+100
	s.player.stack = {"type":"milk","n":5,"inc":0}
	s.zombies.clear()
	for i in 3:
		var z := s._zombies.new_zombie(s.player.x+120+i*45,s.player.y+(i-1)*90,["normal","granny","flag"][i],false,s.mod_by("C",0),3)
		s.zombies.append(z)
	s.combat.cooldown = 0
	s.aim_in = Vector2.RIGHT; s.quick_shot = true; s.upd_combat(0.02)
	moo.set_lifecycle(true,false)
	world.cam_snapped = false; world._process(0); hud._process(0)
	world.queue_redraw(); hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/weapons-night.png"))
	print("  dash visible=%s shots=%d paused=%s" % [hud.controls.dash_btn.visible,s.shots.size(),moo.paused])
	ok = ok and hud.controls.dash_btn.visible and s.player.stack.n == 4
	# Menu and suspension clear held combat and don't confuse movement ownership.
	s.fire_in = true; s.quick_shot = true; s.dash_request = true; moo.set_lifecycle(false,false)
	ok = ok and not s.fire_in and not s.quick_shot and not s.dash_request
	moo.set_lifecycle(true,false)
	s.dispose()
	print(("PASS" if ok else "FAIL")+" windowed_weapons")
	quit(0 if ok else 1)

extends SceneTree
## Long-run performance drift (ADR 0026). A full chapter-3 farm (all pads incl.
## weapons, 13 helpers, four belts, six counters) runs 32 simulated minutes in the
## real scene with day/night, zombies and the fight bot playing. The camera repeats a fixed 10-view tour of the bakery district every
## 10 rendered frames, so every minute draws the same views and only game state
## can change the cost. Checks:
##   - mean draw CPU and update CPU of the last 5 minutes within 15% of minutes 5-10;
##   - every growing collection plateaus (late peak <= 1.25x early peak + 5) and
##     stays under a hard cap; object/node counts and static memory stay flat.
## Reported, not asserted: the slowest phase-boundary steps (dusk/sunrise) and
## the slowest ordinary step (MOO_PERF_VERBOSE=1 logs steps over 8 ms).
## Headless runs have no baked item textures, so 1x1 stand-ins make draw use the
## same one-quad-per-item path as the phone.
const DT := 1.0 / 30.0
const MINUTES := 32.0
const SAMPLE_EVERY := 30  # simulation steps per rendered frame
const POLY_BUDGET := 40
var ok := true
var save_dir := "user://test_perf_drift_%d" % OS.get_process_id()
var verbose := OS.get_environment("MOO_PERF_VERBOSE") != ""

func expect(value: bool, label: String) -> void:
	ok = value and ok
	print("  %s %s" % ["ok" if value else "BAD", label])

func _initialize() -> void:
	create_timer(300.0).timeout.connect(func():
		print("FAIL perf_drift timed out")
		quit(1))
	run.call_deferred()

func sizes(sim: MooSim) -> Dictionary:
	var q := 0
	var slots := 0
	for m in sim.live():
		if m.has("q"): q += m.q.size()
		for k in ["tray", "box", "cash", "hopper"]:
			if m.has(k): slots += m[k].get("item_slots", []).size() + m[k].get("arriving_slots", []).size()
	var pending := 0
	for e in [sim.player] + sim.helpers:
		pending += e.stack.get("pending_ids", []).size()
	return {"flyers": sim.flyers.size(), "floaters": sim.floaters.size(), "toasts": sim.toasts.size(),
		"sparks": sim.sparks.size(), "ground": sim.ground.size(), "leaving": sim.leaving.size(),
		"queue": q, "events": sim.events.size(), "zombies": sim.zombies.size(), "shots": sim.shots.size(),
		"checkpoint_kb": int(var_to_str(sim.checkpoints).length() / 1024), "slots": slots, "pending": pending,
		"rr": Paint.round_points.size(), "ell": Paint.ellipse_points.size(), "txt": Paint.text_sizes.size(),
		"col": Paint.color_cache.size(), "meshes": Paint.shape_meshes.size(), "seen": Paint.shape_seen.size(),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1)}

func trimmed(a: Array) -> float:
	var b := a.duplicate()
	b.sort()
	return mean(b.slice(0, int(b.size() * 0.99)))

func mean(a: Array) -> float:
	var t := 0.0
	for v in a: t += v
	return t / maxf(1.0, a.size())

func run() -> void:
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
	if Paint.item_textures.is_empty():
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		for kind in ["corn", "milk", "egg", "coin", "cheese", "wheat", "bread", "apple", "pie"]:
			Paint.item_textures[kind] = ImageTexture.create_from_image(img)
	hud.start(1)
	var sim: MooSim = moo.sim
	sim.autosave = false
	sim.rng.seed = 5
	sim.toasts.clear()
	for p in sim.pads:
		p.paid = p.cost
		sim.apply_pad(p, true)
	sim.compute_reveal()
	sim.travel_to(2)
	expect(sim.S.ch == 2 and sim.S.done and sim.helpers.size() == 13 and sim.belts.size() == 4, "full chapter-3 farm: all %d pads, 13 helpers, 4 belts" % sim.pads.size())
	var bot := MooFightBot.new(sim)  # real play: harvest ammo, fight night zombies
	# Camera tour: the 9 bakery cells plus the arrival spot, on the cell-border paths.
	var tour: Array = [Vector2(sim.player.x, sim.player.y)]
	for r in 3:
		for c in 3:
			var o := MooSim.cell_xy(2, c, r)
			tour.append(Vector2(o.x + MooSim.CW / 2, o.y + 4))
	var poly_late := []
	var step_ms := {}  # minute -> [ms per simulation step]
	var phase_spikes := {}  # phase name -> [ms of the boundary step]
	var step_max := 0.0
	var draw_ms := {}  # minute -> [ms]
	var upd_ms := {}
	var series := {}  # metric -> {minute: peak}
	var steps := int(MINUTES * 60.0 / DT)
	var step := 0
	var frame := 0
	var start_objects := {}
	while step < steps:
		var upd_us := 0
		for i in SAMPLE_EVERY:
			bot.tick()
			var phase_before := sim.phase_idx()
			var t0 := Time.get_ticks_usec()
			sim.update(DT)
			var one := Time.get_ticks_usec() - t0
			upd_us += one
			var minute_now := int(sim.T / 60.0)
			if not step_ms.has(minute_now): step_ms[minute_now] = []
			step_ms[minute_now].append(one / 1000.0)
			if sim.phase_idx() != phase_before:
				var name: String = ["sunrise", "midday", "evening", "dusk"][sim.phase_idx()]
				if not phase_spikes.has(name): phase_spikes[name] = []
				phase_spikes[name].append(one / 1000.0)
			else:
				step_max = maxf(step_max, one / 1000.0)
				if verbose and one > 8000:
					var kinds := {}
					for ev in sim.events: kinds[ev.kind] = kinds.get(ev.kind, 0) + 1
					print("  SLOW step %.2fms T=%.1f time=%.3f zombies=%d hearts=%d events=%s" % [one / 1000.0, sim.T, sim.S.time, sim.zombies.size(), sim.S.hearts, str(kinds)])
			moo.audio.consume(sim.events)
			sim.events.clear()
		step += SAMPLE_EVERY
		var view: Vector2 = tour[frame % tour.size()]
		frame += 1
		var real_player := Vector2(sim.player.x, sim.player.y)
		sim.player.x = view.x; sim.player.y = view.y
		world.cam_snapped = false
		world._process(0.0)  # camera + queue_redraw only (delta 0 adds no game time)
		sim.player.x = real_player.x; sim.player.y = real_player.y
		hud._process(DT)
		var polys_before := Paint.polygon_calls
		await process_frame
		var minute := int(sim.T / 60.0)
		if minute >= int(MINUTES) - 5: poly_late.append(Paint.polygon_calls - polys_before)
		if not draw_ms.has(minute):
			draw_ms[minute] = []; upd_ms[minute] = []
		draw_ms[minute].append(world.draw_cpu_us / 1000.0)
		upd_ms[minute].append(upd_us / 1000.0 / SAMPLE_EVERY)
		var sz := sizes(sim)
		if start_objects.is_empty() and sim.T >= 300.0: start_objects = sz.duplicate()
		for k in sz:
			if not series.has(k): series[k] = {}
			series[k][minute] = maxf(series[k].get(minute, -INF), sz[k])
		if verbose and step % (SAMPLE_EVERY * 60) == 0:
			print("  t=%5.0fs draw=%.3fms upd=%.4fms %s" % [sim.T, mean(draw_ms[minute]), mean(upd_ms[minute]), str(sz)])
	var last := sizes(sim)
	var d_early := []; var u_early := []; var d_late := []; var u_late := []
	for m in draw_ms:
		if m >= 5 and m < 10: d_early.append_array(draw_ms[m]); u_early.append_array(upd_ms[m])
		if m >= int(MINUTES) - 5 and m < int(MINUTES): d_late.append_array(draw_ms[m]); u_late.append_array(upd_ms[m])
	var s_early := []; var s_late := []
	for m in step_ms:
		if m >= 5 and m < 10: s_early.append_array(step_ms[m])
		if m >= int(MINUTES) - 5 and m < int(MINUTES): s_late.append_array(step_ms[m])
	var te := trimmed(s_early); var tl := trimmed(s_late)
	if verbose:
		var trend := []
		for m in range(int(MINUTES)):
			if step_ms.has(m): trend.append("%d:%.3f" % [m, trimmed(step_ms[m])])
		print("  per-minute trimmed update ms: ", " ".join(trend))
	var de := mean(d_early); var dl := mean(d_late)
	var ue := mean(u_early); var ul := mean(u_late)
	print("  sim %.0fs, %d rendered frames: draw %.3f -> %.3f ms (%+.1f%%), update %.4f -> %.4f ms/step (%+.1f%%)" % [sim.T, frame, de, dl, (dl / de - 1) * 100, ue, ul, (ul / ue - 1) * 100])
	expect(sim.T >= 30 * 60, "ran %.1f simulated minutes" % (sim.T / 60.0))
	var spikes := []
	for k in phase_spikes:
		var a: Array = phase_spikes[k]
		a.sort()
		spikes.append("%s n=%d mean %.2f max %.2f ms" % [k, a.size(), mean(a), a[-1]])
	print("  phase boundary steps: %s; slowest ordinary step %.2f ms; nights %d, hearts %d" % [", ".join(spikes), step_max, sim.S.cn, sim.S.hearts])
	expect(sim.S.cn >= 5, "nights with zombies happened during the run (%d)" % sim.S.cn)
	expect(dl <= de * 1.15, "draw CPU last 5 min within 15% of minutes 5-10")
	# Rare long A* steps at night (backlog) swing a plain mean; the slowest 1% are
	# reported above and excluded here so the check measures sustained cost.
	expect(tl <= te * 1.15, "update CPU (1%%-trimmed mean %.4f -> %.4f ms/step, %+.1f%%) last 5 min within 15%% of minutes 5-10" % [te, tl, (tl / te - 1) * 100])
	# Godot 4 builds a GPU buffer per polygon command (~14us CPU on a desktop);
	# repeated shapes must come from the mesh cache (ADR 0026).
	var pm := mean(poly_late)
	expect(pm <= POLY_BUDGET, "uncached polygon commands per frame %.1f <= %d (cached meshes %d)" % [pm, POLY_BUDGET, Paint.shape_meshes.size()])
	# Hard caps: gameplay collections (rate-bounded by lifetimes/capacities) and Paint caches.
	var caps := {"zombies": 40, "shots": 200, "checkpoint_kb": 256, "flyers": 120, "floaters": 40, "toasts": 6, "sparks": 120, "ground": 400, "leaving": 30, "queue": 36,
		"events": 200, "slots": 1000, "pending": 60, "rr": 512, "ell": 256, "txt": 1024, "col": 256, "meshes": 1024, "seen": 4096}
	var report := []
	for k in caps:
		var early := -INF
		var late := -INF
		for m in series[k]:
			if m >= 5 and m < 16: early = maxf(early, series[k][m])
			if m >= 16: late = maxf(late, series[k][m])
		report.append("%s %d/%d" % [k, early, late])
		expect(late <= caps[k] and late <= early * 1.25 + 5, "%s plateaus: peak %d in min 5-16, %d after (cap %d)" % [k, early, late, caps[k]])
	for k in ["objects", "nodes", "orphans"]:
		expect(last[k] <= start_objects[k] + 50, "%s count flat (%d at 5 min, %d at end)" % [k, start_objects[k], last[k]])
	expect(last.mem_mb <= start_objects.mem_mb + 8.0, "static memory flat (%.1f MB at 5 min, %.1f MB at end)" % [start_objects.mem_mb, last.mem_mb])
	print(("PASS" if ok else "FAIL") + " perf_drift")
	quit(0 if ok else 1)

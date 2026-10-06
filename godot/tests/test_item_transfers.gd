extends SceneTree
## Spatial pickup, stable holes/reservations and concurrent incoming/Toss regression.
const DT := 1.0 / 30.0
var ok := true

func expect(condition: bool, label: String) -> void:
	ok = condition and ok
	print("  %s %s" % ["ok" if condition else "BAD", label])

func same_point(a: Dictionary, b: Dictionary) -> bool:
	return Vector2(a.x - b.x, a.y - b.y).length() < 0.001

func pickup_sides() -> void:
	for side in ["left","right","above"]:
		var sim := MooSim.new(61)
		sim.autosave = false
		var tray = sim.mod_by("B",0).tray
		tray.n = 6
		var slots: Array = sim.visible_slots(tray).duplicate()
		var selected: int = 0 if side == "left" else (5 if side == "right" else 3)
		var source := sim.pile_pos(tray.rect,selected,tray.type)
		sim.player.x = source.x + (-30 if side == "left" else (30 if side == "right" else 0))
		sim.player.y = source.y - (30 if side == "above" else 0)
		expect(sim.take(tray,sim.player), "pickup from %s succeeds" % side)
		var flight: Dictionary = sim.flyers.back()
		expect(same_point({"x":flight.x1,"y":flight.y1},source), "pickup from %s launches nearest drawn item" % side)
		slots.erase(selected)
		expect(sim.visible_slots(tray) == slots, "pickup from %s leaves all surviving slot IDs unmoved" % side)
		expect(tray.n == 5 and tray.inc == 0 and sim.player.stack.n == 1 and sim.player.stack.inc == 1, "pickup preserves source/destination count invariant")
		sim.dispose()
	var sim := MooSim.new(62)
	sim.autosave = false
	var tray = sim.mod_by("B",0).tray
	tray.rect = {"x":100.0,"y":100.0,"w":40.0,"h":32.0}
	tray.n = 12
	sim.visible_slots(tray)
	var base := sim.pile_pos(tray.rect,0,tray.type)
	sim.player.x = base.x; sim.player.y = base.y
	var top := sim.pile_pos(tray.rect,10,tray.type)
	sim.take(tray,sim.player)
	expect(same_point({"x":sim.flyers.back().x1,"y":sim.flyers.back().y1},top), "stacked pickup removes nearest exposed top item rather than buried closest base")
	var next_top := sim.pile_pos(tray.rect,6,tray.type)
	sim.take(tray,sim.player)
	expect(same_point({"x":sim.flyers.back().x1,"y":sim.flyers.back().y1},next_top), "repeated pickup exposes next item in the same pile without moving other piles")
	expect(not sim.visible_slots(tray).has(10) and not sim.visible_slots(tray).has(6), "removed layered slots remain holes")
	sim.dispose()

func nearest_harvest() -> void:
	var sim := MooSim.new(67)
	sim.autosave = false
	var field = sim.mod_by("A",0)
	for tile in field.tiles: tile.t = 5.0
	field.tiles[0].t = 0.0; field.tiles[1].t = 0.0
	sim.player.x = field.tiles[0].x + 30
	sim.player.y = field.tiles[0].y
	sim.act()
	expect(field.tiles[1].t == MooSim.REGROW and field.tiles[0].t == 0.0, "harvest picks closer of two ripe nearby tiles instead of first array entry")
	var flight: Dictionary = sim.flyers.back()
	expect(same_point({"x":flight.x1,"y":flight.y1},{"x":field.tiles[1].x,"y":field.tiles[1].y - 12}), "harvest launch originates at selected ripe tile")
	sim.dispose()

func production_and_saves() -> void:
	var sim := MooSim.new(63)
	sim.autosave = false
	var barn = sim.mod_by("B",0)
	var tray = barn.tray
	tray.n = 6
	var expected: Array = sim.visible_slots(tray).duplicate()
	var point := sim.pile_pos(tray.rect,3,tray.type)
	sim.player.x = point.x; sim.player.y = point.y
	sim.take(tray,sim.player)
	expected.erase(3)
	var save_dir := "user://test_transfers_%d" % OS.get_process_id()
	sim.save_dir = save_dir; sim.cur_slot = 1
	sim.autosave = true
	sim.save(true)
	sim.autosave = false
	var loaded := MooSim.new(64)
	loaded.autosave = false; loaded.save_dir = save_dir
	expect(loaded.start_slot(1), "sparse tray save loads from an actual slot file")
	expect(loaded.visible_slots(loaded.mod_by("B",0).tray) == expected, "save round-trip preserves exact visible tray holes")
	loaded.delete_slot(1); loaded.dispose()
	DirAccess.remove_absolute(save_dir)
	var legacy := MooSim.new(65)
	legacy.autosave = false
	legacy.apply_state({"ver":9,"bx":{"0B":{"t":5}}})
	expect(legacy.visible_slots(legacy.mod_by("B",0).tray) == [0,1,2,3,4], "legacy count-only tray reconstructs contiguous slots")
	legacy.dispose()
	barn.hopper.n = 1; barn.hopper.inc = 0
	for unit in barn.units: unit.timer = barn.period
	sim.upd_machine(barn,DT)
	expect(tray.n == 6 and tray.inc == 1 and tray.arriving_slots == [3], "new production reserves the first free hole while incoming")
	expect(sim.visible_slots(tray) == expected, "reserved production slot remains hidden until arrival")
	var snapshot := sim.snapshot()
	expect(snapshot.bx["0B"].t == 5 and snapshot.bx["0B"].tp == expected, "snapshot excludes unarrived production while preserving stable holes")
	sim.player.x = sim.mod_by("A",0).rect.x - 25
	sim.player.y = sim.mod_by("A",0).rect.y - 25
	for i in range(30): sim.update(DT)
	var visible: Array = sim.visible_slots(tray).duplicate()
	visible.sort()
	expect(visible == [0,1,2,3,4,5] and tray.inc == 0, "completed production fills free hole with no survivor reshuffle")
	sim.dispose()
	# A tray containing only reserved production cannot be picked up early.
	var pending := MooSim.new(66)
	pending.autosave = false
	var machine = pending.mod_by("B",0)
	machine.hopper.n = 1
	for unit in machine.units: unit.timer = machine.period
	pending.upd_machine(machine,DT)
	expect(not pending.take(machine.tray,pending.player), "pickup rejects incoming-only tray stock")
	expect(machine.tray.n == 1 and machine.tray.inc == 1 and pending.player.stack.n == 0, "rejected early pickup preserves reservation/counts")
	pending.dispose()

func toss_incoming() -> void:
	for stable in [0,3]:
		var sim := MooSim.new(70 + stable)
		sim.autosave = false
		var tray = sim.mod_by("B",0).tray
		tray.n = 5
		sim.player.stack = {"type":"milk" if stable > 0 else null,"n":stable,"inc":0}
		sim.take(tray,sim.player)
		if stable > 0: sim.take(tray,sim.player)
		var incoming: Array = sim.flyers.duplicate()
		var bin = sim.mod_by("A",0).bin
		var foot := MooSim.ctr(bin)
		sim.player.x = foot.x; sim.player.y = foot.y
		sim.player.face = -1; sim.player.moving = true; sim.player.lean = 0.7
		var launch := sim.stack_pos(sim.player,stable - 1) if stable > 0 else {}
		var before: int = sim.flyers.size()
		sim.act()
		if stable == 0:
			expect(sim.flyers.size() == before and sim.player.stack.n == 1 and sim.player.stack.inc == 1, "Toss skips incoming-only stack instead of making it disappear")
		else:
			var toss: Dictionary = sim.flyers.back()
			expect(toss.get("kind","") == "toss" and same_point({"x":toss.x1,"y":toss.y1},launch), "Toss launches actual top visible carried item while arrivals remain pending")
			var mouth := {"x":bin.x + bin.w / 2,"y":bin.y + 8}
			expect(same_point(toss.to.call(),mouth), "Toss targets the bin mouth")
			var pose_flight: Dictionary = toss.duplicate()
			pose_flight.t = 0.0
			var start_pose := sim.flight_pose(pose_flight)
			pose_flight.t = pose_flight.dur * 0.25
			var quarter_pose := sim.flight_pose(pose_flight)
			pose_flight.t = pose_flight.dur * 0.5
			var mid_pose := sim.flight_pose(pose_flight)
			pose_flight.t = pose_flight.dur * 0.85
			var sink_pose := sim.flight_pose(pose_flight)
			pose_flight.t = pose_flight.dur
			var end_pose := sim.flight_pose(pose_flight)
			expect(same_point(start_pose,launch) and start_pose.scale == 1.0 and start_pose.alpha == 1.0, "Toss starts exactly at the visible stack with full size/opacity")
			expect(absf(quarter_pose.x - launch.x) < absf(mouth.x - launch.x) * 0.25 and mid_pose.y < minf(launch.y,mouth.y), "Toss eases off its source and arcs above both endpoints")
			expect(sink_pose.scale < 1.0 and sink_pose.scale > end_pose.scale and sink_pose.alpha > 0 and sink_pose.alpha < 1.0, "Toss shrinks and fades gradually while sinking into mouth")
			expect(same_point(end_pose,mouth) and is_equal_approx(end_pose.scale,0.25) and is_zero_approx(end_pose.alpha), "Toss ends at the mouth fully faded at quarter size")
			sim.player.x += 20; sim.player.y += 30; sim.player.face = 1
			expect(same_point(toss.to.call(),mouth), "Toss mouth target remains fixed after player movement")
			sim.act(); sim.act()
			var all_visible_tossed: int = sim.flyers.size()
			sim.act()
			expect(sim.flyers.size() == all_visible_tossed and sim.player.stack.n == 2 and sim.player.stack.inc == 2, "repeated Toss consumes only arrived items and stops at reserved stock")
			for i in incoming.size():
				expect(same_point(incoming[i].to.call(),sim.stack_pos(sim.player,i)), "pending arrival follows remaining stack position after Toss")
		var counts_valid := true
		for i in range(90):
			sim.update(DT)
			if sim.player.stack.n < 0 or sim.player.stack.inc < 0 or sim.player.stack.inc > sim.player.stack.n:
				counts_valid = false
		expect(counts_valid, "incoming + Toss maintains nonnegative visible/reserved stack counts")
		expect(sim.player.stack.n == 0 and sim.player.stack.inc == 0 and sim.player.stack.type == null, "incoming items settle and are then tossed without ghost inventory")
		sim.dispose()

func _init() -> void:
	pickup_sides()
	nearest_harvest()
	production_and_saves()
	toss_incoming()
	print(("PASS" if ok else "FAIL") + " item_transfers")
	quit(0 if ok else 1)

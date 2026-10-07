extends SceneTree
## Escalation, customer turning, safe A* chase, Gary and isolated night persistence.
const DT := 1.0 / 30.0
var ok := true
var directory := "user://test-night-%d" % OS.get_process_id()

class NoRouteSim extends MooSim:
	var deny := false
	var requests := 0
	func find_path(ax: float, ay: float, bx: float, by: float, avoid_fields: bool = false):
		requests += 1
		return null if deny else super.find_path(ax, ay, bx, by, avoid_fields)

func expect(value: bool, label: String) -> void:
	ok = value and ok
	print("  %s %s" % ["ok" if value else "BAD", label])

# JSON floats can differ by one ULP on this engine. Game values remain within 1e-8.
func same_state(a, b) -> bool:
	if (a is float or a is int) and (b is float or b is int): return absf(float(a)-float(b)) < 1e-8
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not same_state(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not same_state(a[i],b[i]): return false
		return true
	return a == b

func beats(sim: MooSim) -> Array:
	return sim.events.filter(func(e): return e.kind == "night_beat").map(func(e): return e.requested)

func enter_night(sim: MooSim, chapter: int, night: int) -> void:
	sim.apply_state({"ver":9,"ch":chapter,"day":night,"time":0.7,"cn":night,"tut":{"gary":2}})
	sim.autosave = false
	sim.begin_night()

func escalation() -> void:
	var sim := MooSim.new(40)
	sim.autosave = false
	var before: int = sim.rng.state
	sim.upd_clock(186)
	expect(sim.zombies.size() == 1 and sim.zombies[0].type == "gary" and beats(sim).is_empty(), "chapter 1 first night contains Gary only")
	var g = sim.zombies[0]
	var point := Vector2(g.x,g.y)
	for i in 600: sim.upd_zombies(DT)
	expect(Vector2(g.x,g.y) == point and sim.events.filter(func(e): return e.kind == "zombie_bite").is_empty(), "gunless Gary waits and cannot bite")
	expect(sim.rng.state == before, "threat scheduling/appearance do not advance economy RNG")
	sim.upd_clock(90)
	expect(sim.zombies.size() == 1 and sim.zombies[0].type == "gary", "sunrise retains unfinished practice actor")
	for chapter in 3:
		var first := 2 if chapter == 0 else 1
		enter_night(sim,chapter,first)
		sim.advance_night(29.99)
		expect(beats(sim) == [2], "ch%d first beat spawns at dusk, second waits for 30s" % chapter)
		sim.zombies.clear()
		sim.advance_night(0.01)
		sim.zombies.clear()
		sim.advance_night(30)
		expect(beats(sim) == [2,4,6] and sim.zombies.size() == 6, "ch%d first real night requests and spawns 2/4/6" % chapter)
		enter_night(sim,chapter,first+1)
		sim.zombies.clear(); sim.advance_night(30)
		sim.zombies.clear(); sim.advance_night(30)
		expect(beats(sim) == [3,5,7], "ch%d next night adds one per beat" % chapter)
	enter_night(sim,1,6)
	sim.advance_night(60)
	expect(sim.zombies.size() == 10 and sim.horde_zombie() == null, "horde never exceeds 10 live actors")
	var crop = sim.mod_by("A",0).rect
	sim.zombies[0].x = crop.x+crop.w/2; sim.zombies[0].y = crop.y+crop.h/2
	var count := sim.zombies.size()
	var wallet: int = sim.S.money
	sim.sunrise()
	expect(sim.zombies.is_empty() and sim.leaving.size() == count and sim.S.money == wallet, "sunrise wakes every zombie without payout or wallet loss")
	expect(sim.leaving.all(func(c): return sim.nav_free(sim.nav_gx(c.x),sim.nav_gy(c.y),true)), "sunrise departures rejoin public paths outside crops/trays/scenery")
	sim.dispose()

func turning() -> void:
	var sim := MooSim.new(42)
	sim.autosave = false
	for fixture in [{"night":false,"near":true},{"night":true,"near":true},{"night":true,"near":false}]:
		sim.fresh_state()
		sim.restore_clock({"day":2,"time":0.8 if fixture.night else 0.3,"cn":2})
		var m = sim.mod_by("C",0)
		m.spawn = 9999.0; m.rep = 3.0
		var slot := MooSim.q_slot(m,0)
		var c := sim.new_cust(slot.x,slot.y,m)
		c.wait = 32.99
		m.q.append(c)
		sim.player.x = c.x if fixture.near else c.x+2000
		sim.player.y = c.y
		sim.upd_counter(m,DT)
		expect(sim.zombies.size() == (1 if fixture.night and fixture.near else 0) and m.q.is_empty() and m.rep == 2.5, "lost customer turns only at night and within 1100px (%s)" % str(fixture))
		if fixture.night and fixture.near:
			var extra := sim.new_cust(slot.x,slot.y,m)
			extra.wait = 0; m.q.append(extra)
			sim.upd_counter(m,1.0)
			expect(extra.wait == 3.0, "night patience accumulates at 3x")
			while sim.zombies.size() < 10: sim.horde_zombie()
			extra.wait = 33; sim.upd_counter(m,DT)
			expect(sim.zombies.size() == 10 and sim.leaving.has(extra), "turned customers share horde cap; overflow leaves")
	sim.dispose()

func routes_and_hits() -> void:
	var sim := NoRouteSim.new(44)
	enter_night(sim,0,2)
	sim.zombies.clear()
	var m = sim.mod_by("C",0)
	var a := sim.new_cust(m.bench.x-30,m.bench.y+m.bench.h/2,m)
	sim.player.x = m.bench.x+m.bench.w+30; sim.player.y = a.y
	sim.turn_customer(a,m)
	var z = sim.zombies[0]
	sim.upd_zombies(DT)
	expect(z.path.size() > 2, "zombie A* route has multiple nodes around a solid counter")
	var safe := true
	for i in 240:
		sim.upd_zombies(DT)
		if not sim.walkable(z.x,z.y) or sim.blocked_at(z.x,z.y,8): safe = false
	expect(safe and MooSim.dist(z,sim.player) < 50, "zombie reaches player without crossing scenery, fog or bounds")
	z.path = []; z.repath = 0; z.state = "chase"
	sim.deny = true
	var previous := Vector2(z.x,z.y)
	for i in 30: sim.upd_zombies(DT)
	expect(Vector2(z.x,z.y) == previous, "unreachable zombie waits instead of moving in a straight line")
	z.x = m.bench.x+m.bench.w/2; z.y = m.bench.y+m.bench.h/2
	sim.upd_zombies(DT)
	expect(sim.walkable(z.x,z.y) and not sim.blocked_at(z.x,z.y,8), "pinned actor is unstuck onto the existing nav grid")
	# All actors eventually receive plans despite the four-plan per-tick cap.
	sim.zombies.clear()
	for j in 10: sim.zombies.append(sim._zombies.new_zombie(sim.player.x+100,sim.player.y,"normal",false,m,3))
	var requests: int = sim.requests
	for j in 3: sim.upd_zombies(DT)
	expect(sim.requests-requests == 10 and sim.zombies.all(func(actor): return actor.repath > 0), "round-robin four-plan budget reaches all ten actors in three ticks")
	var biting = sim.zombies[0]
	sim.zombies = [biting]
	biting.x = sim.player.x+5; biting.y = sim.player.y
	biting.state = "windup"; biting.st = 0.55
	sim.events.clear()
	sim.upd_zombies(0.54)
	expect(sim.events.filter(func(e): return e.kind == "zombie_bite").is_empty(), "bite warning lasts at least 0.55 seconds")
	sim.upd_zombies(0.02)
	expect(sim.events.any(func(e): return e.kind == "zombie_bite") and biting.state == "recover", "completed bite emits a hearts hook then enters 0.9-second recovery")
	sim.deny = false
	for chapter in 3:
		enter_night(sim,chapter,2)
		for actor in sim.zombies:
			var normal: int = [3,6,12][chapter]
			var expected: int = int(ceil(normal*1.5)) if actor.type == "karen" else normal + ([1,2,4][chapter]*2 if actor.type == "granny" else 0)
			if actor.big: expected *= 3
			expect(actor.hp == expected, "chapter %d %s HP follows accepted multipliers" % [chapter,actor.type])
	for chapter in 3:
		enter_night(sim,chapter,2)
		sim.zombies.clear()
		var actor = sim._zombies.new_zombie(sim.player.x,sim.player.y,"normal",false,m,3)
		sim.zombies.append(actor)
		for hit in 2: sim.hit_zombie(actor,[1,2,4][chapter])
		expect(actor in sim.zombies, "ch%d normal survives two base-weapon hits" % chapter)
		sim.hit_zombie(actor,[1,2,4][chapter])
		expect(actor not in sim.zombies, "ch%d normal cures on third base-weapon hit" % chapter)
		var granny = sim._zombies.new_zombie(sim.player.x,sim.player.y,"granny",false,m,3)
		var big = sim._zombies.new_zombie(sim.player.x,sim.player.y,"normal",true,m,3)
		expect(granny.hp == [5,10,20][chapter] and big.hp == [9,18,36][chapter], "ch%d Granny adds two hits and big triples HP" % chapter)
	sim.dispose()

func persistence_and_gary() -> void:
	var sim := MooSim.new(47)
	sim.autosave = false; sim.save_dir = directory
	sim.upd_clock(186)
	var g = sim.zombies[0]
	# A fixture pad tests the future armory seam; no weapon content is introduced here.
	var pad = sim.visible_pads()[2]
	pad.fx = "gun"; pad.v = 1; pad.cost = 100
	sim.S.money = 99
	expect(sim.gary_guide() == null, "gunless guide keeps normal loop below weapon cost")
	sim.S.money = 100
	expect(sim.guide_raw() == MooSim.ctr(pad), "affordable Milk squirter overrides other pads while Gary waits")
	sim.S.money = 0
	sim.S.gun = 1
	for i in 1801: sim.upd_zombies(DT)
	expect(sim.zombies.is_empty() and sim.S.tut.gary == 2 and sim.S.money == 0, "armed Gary trips after 60s without bites/rewards")
	sim.fresh_state(); sim.upd_clock(126)
	g = sim.zombies[0]
	sim.hit_zombie(g,1)
	expect(sim.S.tut.gary == 2 and sim.S.money == 0 and sim.zombies.is_empty() and sim.sparks.size() == 18, "Gary hit emits 18 straw pieces, no reward, and marks once-per-slot flag")
	sim.write_slot(1,sim.snapshot())
	sim.fresh_state(); sim.write_slot(2,sim.snapshot())
	var bytes := FileAccess.get_file_as_string(sim.slot_path(2))
	sim.apply_state(sim.read_slot(1)); sim.evening_gary()
	expect(sim.S.tut.gary == 2 and sim.zombies.is_empty(), "reload does not replay completed Gary")
	enter_night(sim,1,2)
	sim.advance_night(31)
	sim.upd_zombies(0.2)
	var night := sim.night_snapshot()
	sim.write_slot(1,sim.snapshot())
	sim.apply_state(sim.read_slot(1))
	expect(same_state(sim.night_snapshot(), night) and sim.events.is_empty(), "disk reload preserves actors, partial beat, HP and exact threat RNG without a spawn event")
	sim.advance_night(28)
	expect(beats(sim).is_empty(), "restored second beat waits for third beat boundary")
	sim.advance_night(1)
	expect(beats(sim) == [7], "restored third beat fires once with correct escalation")
	sim.write_slot(1,sim.snapshot())
	expect(FileAccess.get_file_as_string(sim.slot_path(2)) == bytes, "night changes leave another slot byte-identical")
	sim.apply_state(sim.read_slot(2))
	expect(sim.S.tut.gary == 0 and sim.zombies.is_empty(), "fresh slot retains its independent Gary/night state")
	sim.apply_state({"ver":9,"ch":0,"day":4,"time":0.85,"cn":4})
	expect(sim.S.tut.gary == 2 and sim.zombies.is_empty(), "legacy advanced save skips Gary and retroactive horde bursts")
	for slot in [1,2]: sim.delete_slot(slot)
	sim.dispose()

func _init() -> void:
	escalation()
	turning()
	routes_and_hits()
	persistence_and_gary()
	print(("PASS" if ok else "FAIL") + " night")
	quit(0 if ok else 1)

extends SceneTree
## Real default-game damage, rollback inventory and cold slot isolation.
var ok := true
var directory := "user://hearts-%d" % OS.get_process_id()

func expect(value: bool, label: String) -> void:
	ok = ok and value
	print("  %s %s" % ["ok" if value else "BAD", label])

func hit(sim: MooSim, kind: String = "normal") -> void:
	var z = sim._zombies.new_zombie(sim.player.x, sim.player.y, kind, false, sim.mod_by("C",0), 3)
	z.state = "windup"; z.st = 0.01
	sim.zombies = [z]
	sim.upd_zombies(0.02)

func run_damage() -> void:
	var sim := MooSim.new(71)
	sim.autosave = false
	expect(sim.S.hearts == 5 and sim.inv_t == 0, "fresh player has five hearts")
	sim.player.stack = {"type":"corn", "n":8, "inc":2, "pending_ids":[1,2]}
	sim.S.money = 97
	hit(sim)
	expect(sim.S.hearts == 4 and sim.inv_t == 1 and sim.player.stack.n == 5 and sim.player.stack.inc == 2, "completed real windup loses one heart and three arrived goods, preserving reservations")
	expect(sim.S.money == 97, "bite never changes wallet")
	hit(sim, "karen")
	expect(sim.S.hearts == 4 and sim.player.stack.n == 5, "simultaneous bite inside immunity loses neither health nor goods")
	sim.upd_hearts(0.99); hit(sim)
	expect(sim.S.hearts == 4, "immunity lasts the full second")
	sim.upd_hearts(0.01)
	sim.player.stack = {"type":"corn", "n":8, "inc":0}
	hit(sim, "karen")
	expect(sim.S.hearts == 3 and sim.player.stack.n == 2, "Karen removes up to six goods after immunity expires")
	sim.inv_t = 0; hit(sim, "gary")
	expect(sim.S.hearts == 3, "Gary never damages the player")
	sim.hurt_player("a boss power")
	var state := sim.snapshot()
	sim.apply_state(JSON.parse_string(JSON.stringify(state, "", true, true)))
	expect(sim.S.hearts == 2 and sim.inv_t == 1, "ordinary reload preserves partial health and remaining immunity")
	sim.sunrise()
	expect(sim.S.hearts == 5 and sim.inv_t == 0, "sunrise completely refills hearts")
	sim.S.hearts = 3
	var gate = sim.pad_named("Buy the dairy")
	gate.paid = gate.cost; sim.apply_pad(gate, false)
	expect(sim.S.hearts == 3, "chapter entry grants no extra healing before sunrise")
	sim.dispose()

func run_rollback() -> void:
	var sim := MooSim.new(72)
	sim.save_dir = directory; sim.start_slot(1)
	sim.S.money = 321
	var upgrade = sim.pads.filter(func(p): return p.fx == "helper")[1]
	upgrade.paid = upgrade.cost; sim.apply_pad(upgrade, false)
	var earlier = sim.pads.filter(func(p): return p.fx == "helper")[0]
	earlier.paid = earlier.cost; sim.apply_pad(earlier, false)
	var helper = sim.helpers[0]
	helper.stack = {"type":"corn", "n":4, "inc":1}
	helper.state = "to"
	var machine = sim.mod_by("B",0)
	machine.tray.n = 3; machine.tray.inc = 1
	machine.tray.item_slots = [0,4,7]; machine.tray.arriving_slots = [7]
	sim.player.stack = {"type":"corn", "n":5, "inc":2}
	sim.S.day = 2; sim.S.time = 0.7-1.0/300.0; sim.S.cn = 1
	sim.upd_clock(1)
	var threat_state: String = sim.checkpoints.dusk.night.rng
	var bank := JSON.stringify(sim.checkpoints)
	expect(sim.checkpoints.dusk.cn == 2 and sim.checkpoints.dusk.night.beat == 0, "dusk captures new night and initial wave exactly once")
	expect(not sim.checkpoints.dusk.has("checkpoints") and not sim.checkpoints.chapter_start.has("checkpoints"), "checkpoint bank is flat with no recursive snapshots")
	sim.write_slot(2, {"money":888,"sentinel":"other slot"})
	var other_bytes := FileAccess.get_file_as_string(sim.slot_path(2))
	sim.S.money = 1; sim.S.tut.gary = 2; sim.S.tut.extra = true; sim.S.hats = ["cowboy"]
	sim.S.stats.cures = 7
	sim.S.hearts = 1; sim.inv_t = 0
	hit(sim, "karen")
	expect(sim.faint != null and sim.faint.checkpoint == "dusk" and sim.faint.cause == "Karen", "normal-night fatal bite names cause and selects dusk")
	var time: float = sim.T
	var clock: float = sim.S.time
	sim.update(10)
	expect(sim.T == time and sim.S.time == clock, "faint freezes production, actors and clock until explicit retry")
	var cold := MooSim.new(99)
	cold.save_dir = directory; cold.start_slot(1)
	expect(cold.S.hearts == 0 and cold.faint != null, "cold reopening preserves pending faint card")
	expect(cold.restore_checkpoint(), "cold retry restores persisted dusk")
	expect(FileAccess.get_file_as_string(cold.slot_path(2)) == other_bytes, "slot 2 remains byte-identical when slot 1 faints and restores")
	expect(cold.S.money == 321 and cold.S.hearts == 5 and cold.inv_t == 0 and cold.faint == null, "retry restores checkpoint wallet and fully healthy player")
	expect(cold.player.stack.n == 5 and cold.player.stack.inc == 0 and cold.helpers.filter(func(h): return h.src_id == "A" and h.dst_id == "D")[0].stack.n == 4 and cold.helpers.filter(func(h): return h.src_id == "A" and h.dst_id == "D")[0].stack.inc == 0, "checkpoint settles held and helper cargo once despite reversed purchase order")
	var restored = cold.mod_by("B",0).tray
	expect(restored.n == 3 and restored.inc == 0 and restored.item_slots == [0,4,7], "checkpoint retains sparse tray IDs including pending goods")
	expect(cold.S.tut.gary == 2 and cold.S.tut.extra and cold.S.hats == ["cowboy"] and cold.S.stats.cures == 7 and cold.S.stats.faints == 1, "retry keeps all tutorial, wardrobe and lifetime statistics")
	expect(str(cold.night_rng.state) == threat_state and cold.night_state.beat == 0, "retry restores threat stream and wave cursor without replay")
	expect(JSON.stringify(sim.checkpoints) == bank, "live play and retry leave immutable backups unchanged")
	cold.save(true)
	var saved = cold.read_slot(1)
	cold.start_slot(1)
	expect(cold.helpers.filter(func(h): return h.src_id == "A" and h.dst_id == "D")[0].stack.n == 4, "ordinary cold reload retains restored helper cargo")
	cold.start_slot(2); cold.S.money = 999; cold.save(true)
	cold.start_slot(1)
	expect(cold.S.money == 321 and cold.checkpoints.dusk.money == 321, "switching slots restores only that slot's health and backups")
	cold.delete_slot(2)
	expect(cold.read_slot(2) == null and cold.read_slot(1).checkpoints == saved.checkpoints, "deleting another slot cannot erase this slot's backups")
	# Chapter entry captures the paid gate and prior district before a boss rollback.
	cold.S.money = 777
	var gate = cold.pad_named("Buy the dairy")
	gate.paid = gate.cost; cold.apply_pad(gate, false)
	expect(cold.checkpoints.chapter_start.ch == 1 and not cold.checkpoints.has("dusk"), "chapter entry replaces baseline and removes previous district dusk")
	var chapter_rng: String = cold.checkpoints.chapter_start.night.rng
	cold.S.money = 2; cold.restore_clock({"day":3,"time":0.8,"cn":3})
	cold.S.hearts = 1; cold.inv_t = 0; hit(cold)
	expect(cold.faint.checkpoint == "chapter_start", "boss-night loss selects chapter start")
	cold.restore_checkpoint()
	expect(cold.S.ch == 1 and cold.S.money == 777 and cold.S.day == 1 and cold.S.cn == 0 and cold.S.time == 0.08, "boss retry restores chapter entry wallet and day-one clock")
	expect(cold.pad_named("Buy the dairy").paid == gate.cost and cold.helpers.size() == 2 and cold.mod_by("B",0).tray.n == 3, "boss retry retains gate, prior district inventory and upgrades")
	expect(str(cold.night_rng.state) == chapter_rng and cold.night_state.beat == -1, "boss retry restores chapter threat RNG while resetting scheduler")
	expect(cold.zombies.is_empty() and cold.S.tut.gary == 2 and cold.S.stats.faints == 2, "boss retry clears real threats while retaining lifetime/tutorial progress")
	for i in range(1,4): cold.delete_slot(i)
	DirAccess.remove_absolute(directory)
	sim.dispose(); cold.dispose()

func run_migration() -> void:
	var sim := MooSim.new(74)
	sim.autosave = false
	var upgrade = sim.pads[0]
	var key: String = "0:" + str(upgrade.name)
	sim.apply_state({"ver":8,"ch":1,"money":123,"day":4,"time":0.8,"cn":4,"pk":{key:upgrade.cost * 0.95}})
	expect(sim.pads[0].paid == sim.pads[0].cost, "legacy finished upgrade remains finished after price rescale")
	expect(sim.S.hearts == 5 and sim.checkpoints.chapter_start.money == 123 and sim.checkpoints.dusk.money == 123, "legacy migrated state acquires health and mid-night fallback backups")
	var cp := JSON.stringify(sim.checkpoints)
	sim.travel_to(0)
	sim.apply_state(sim.snapshot())
	expect(JSON.stringify(sim.checkpoints) == cp, "travel and ordinary reload never replace checkpoints")
	sim.fresh_state()
	sim.upd_clock(186)
	var gary_id: int = sim.zombies[0].id
	sim.restore_clock({"day":3,"time":0.8,"cn":3})
	sim.S.hearts = 1; sim.hurt_player("a boss power")
	sim.restore_checkpoint()
	expect(sim.S.tut.gary == 1 and sim.zombies.size() == 1 and sim.zombies[0].id == gary_id, "chapter restart keeps unfinished Gary without duplicating him")
	sim.hit_zombie(sim.zombies[0], 1)
	sim.restore_clock({"day":3,"time":0.8,"cn":3})
	sim.S.hearts = 1; sim.inv_t = 0; sim.hurt_player("a boss power")
	sim.restore_checkpoint()
	expect(sim.S.tut.gary == 2 and sim.zombies.is_empty(), "completed Gary never returns after chapter restart")
	sim.dispose()

func _init() -> void:
	run_damage(); run_rollback(); run_migration()
	print(("PASS" if ok else "FAIL") + " hearts")
	quit(0 if ok else 1)

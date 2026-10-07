extends SceneTree
## Transition ordering, reload/migration, chapter ownership and slot isolation.
var ok := true
var save_dir := "user://test_clock_%d" % OS.get_process_id()

func expect(value: bool, label: String) -> void:
	ok = value and ok
	print("  %s %s" % ["ok" if value else "BAD", label])

func clock_state(sim: MooSim) -> Array:
	return [sim.S.day, sim.S.time, sim.S.cn]

func phases(sim: MooSim) -> Array:
	return sim.events.filter(func(e): return e.kind == "phase").map(func(e): return e.phase)

func stable(d: Dictionary) -> Dictionary:
	var result: Dictionary = JSON.parse_string(JSON.stringify(d))
	result.erase("t")
	return result

func boundaries(sim: MooSim) -> void:
	expect(clock_state(sim) == [1, 0.08, 0] and sim.phase_idx() == 0, "fresh game starts at day 1, 08%, before any night")
	expect(sim.darkness() == 0.0 and sim.clock_label() == "Day 1 · Morning", "fresh morning is bright with a readable clock")
	var rng_before: int = sim.rng.state
	sim.upd_clock(51.0)
	expect(sim.phase_idx() == 1 and is_equal_approx(sim.S.time, 0.25), "midday starts at 75s of the 300s day")
	sim.upd_clock(75.0)
	expect(sim.phase_idx() == 2 and is_equal_approx(sim.S.time, 0.5), "evening starts at 150s")
	sim.upd_clock(60.0)
	expect(sim.is_night() and sim.S.cn == 1 and not sim.is_boss_night(), "first dusk is 186s after fresh start and counts night 1 once")
	expect(is_equal_approx(sim.darkness(), 0.3) and sim.clock_label() == "Night 1", "dusk darkness and night label use the current phase")
	sim.upd_clock(18.0)
	expect(is_equal_approx(sim.darkness(), 0.6), "night reaches 60% darkness at 76% of the day")
	sim.upd_clock(72.0)
	expect(clock_state(sim) == [2, 0.0, 1] and not sim.is_night(), "90s night ends at sunrise, retaining completed-night count")
	expect(phases(sim) == [1, 2, 3, 0], "phase events fire exactly once in chronological order")
	expect(sim.events.filter(func(e): return e.kind == "sunrise").size() == 1, "one dawn event per rollover")
	expect(is_equal_approx(sim.darkness(), 0.55), "dawn retains v9's short darkness fade")
	sim.upd_clock(18.0)
	expect(is_equal_approx(sim.darkness(), 0.0), "dawn fades completely after 18 seconds")
	expect(sim.rng.state == rng_before, "clock, toasts and transitions consume no gameplay RNG")
	# A coarse clock-only step must not skip nights or accumulate wall-clock time.
	sim.reset_clock()
	sim.events.clear()
	sim.upd_clock(786.0)
	expect(clock_state(sim) == [3, 0.7, 3] and sim.is_boss_night(), "night 3 starts at 786s and is a boss-night hook")
	expect(phases(sim) == [1,2,3,0,1,2,3,0,1,2,3], "coarse tick visits every intermediate phase")
	sim.upd_clock(900.0)
	expect(sim.S.cn == 6 and sim.S.day == 6 and sim.is_boss_night(), "boss-night hook repeats every third night")
	var before := clock_state(sim)
	sim.upd_clock(0.0)
	sim.upd_clock(-1.0)
	sim.upd_clock(INF)
	expect(clock_state(sim) == before, "invalid or nonpositive clock deltas do not advance time")

func chapter_and_ticks(sim: MooSim) -> void:
	sim.fresh_state()
	sim.S.time = 0.7 - 1.0 / 9000.0
	var rng_before: int = sim.rng.state
	sim.update(1.0 / 30.0)
	expect(sim.is_night() and sim.S.cn == 1 and is_equal_approx(sim.T, 1.0 / 30.0), "real simulation tick advances the clock before production")
	expect(sim.rng.state == rng_before, "crossing dusk through update does not add random draws")
	sim.upd_clock(600.0)
	var gate = sim.pad_named("Buy the dairy")
	gate.paid = gate.cost
	sim.apply_pad(gate, false)
	expect(sim.S.ch == 1 and clock_state(sim) == [1,0.08,0], "new chapter starts its own day 1 and night counter")
	sim.upd_clock(80.0)
	var before := clock_state(sim)
	expect(sim.travel_to(0) and clock_state(sim) == before, "menu travel back to an owned district does not reset the clock")
	sim.apply_pad(gate, false)
	expect(clock_state(sim) == before, "reapplying an already-owned gate does not restart the chapter")
	# Fine stepping agrees with coarse stepping at boundaries over multiple days.
	sim.reset_clock()
	for i in range(23580): sim.upd_clock(1.0 / 30.0)
	expect(sim.S.day == 3 and sim.S.cn == 3 and is_equal_approx(sim.S.time, 0.7), "30Hz stepping hits night 3 at the same 786s boundary")

func saves(sim: MooSim) -> void:
	sim.fresh_state()
	sim.S.time = 0.7 - 3e-8
	var before_dusk: float = sim.S.time
	sim.write_slot(1, sim.snapshot())
	sim.apply_state(sim.read_slot(1))
	expect(sim.S.time == before_dusk and not sim.is_night() and sim.S.cn == 0, "disk float precision preserves a moment just before dusk")
	sim.upd_clock(0.001)
	expect(sim.is_night() and sim.S.cn == 1 and phases(sim) == [3], "post-reload boundary fires the first dusk exactly once")
	sim.fresh_state()
	sim.S.money = 337
	sim.pads[0].paid = 17
	sim.restore_clock({"day":3,"time":0.81,"cn":3})
	sim.write_slot(1, sim.snapshot())
	var slot1 := stable(sim.snapshot())
	sim.fresh_state()
	sim.restore_clock({"day":2,"time":0.76,"cn":2})
	sim.S.money = 991
	sim.write_slot(2, sim.snapshot())
	var bytes2 := FileAccess.get_file_as_string(sim.slot_path(2))
	sim.apply_state(sim.read_slot(1))
	expect(stable(sim.snapshot()) == slot1, "reload restores every field, including day/phase/night and partial payment")
	expect(sim.is_boss_night() and sim.events.is_empty(), "loading a boss night does not replay dusk or emit spawns")
	sim.upd_clock(1.0)
	expect(sim.S.cn == 3 and sim.events.is_empty(), "first tick after reload does not count the same night twice")
	sim.write_slot(1, sim.snapshot())
	expect(FileAccess.get_file_as_string(sim.slot_path(2)) == bytes2, "slot 1 clock/save changes leave slot 2 byte-identical")
	sim.apply_state(sim.read_slot(2))
	expect(sim.S.money == 991 and clock_state(sim) == [2,0.76,2], "switching slots restores their independent clocks and wallets")
	sim.apply_state({"ver":9,"ch":0,"money":47,"pk":{"0:Corn conveyor":23}})
	expect(clock_state(sim) == [1,0.08,0] and sim.S.money == 47 and sim.pads[0].paid == 23, "old native saves default to day 1 without changing wallet/payments")
	sim.apply_state({"ver":9,"ch":0,"done":true,"day":4,"time":0.75,"cn":4})
	expect(sim.S.ch == 1 and clock_state(sim) == [4,0.75,4], "replaying migrated gates preserves the saved clock after world rebuild")
	sim.restore_clock({"day":0,"time":NAN,"cn":-5})
	expect(clock_state(sim) == [1,0.08,0], "invalid metadata normalizes to a valid fresh clock")
	sim.restore_clock({"day":4,"time":0.75})
	expect(sim.S.cn == 4, "legacy day/time without cn infers the current chapter night count")

func _init() -> void:
	var sim := MooSim.new(23)
	sim.autosave = false
	sim.save_dir = save_dir
	boundaries(sim)
	chapter_and_ticks(sim)
	saves(sim)
	for slot in [1,2]: sim.delete_slot(slot)
	sim.dispose()
	print(("PASS" if ok else "FAIL") + " clock")
	quit(0 if ok else 1)

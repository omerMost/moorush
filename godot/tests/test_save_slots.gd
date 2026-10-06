extends SceneTree
## Persisted state round-trips, real gameplay, migration and slot reset isolation.
var ok := true
var simulations: Array = []
const SAVE_DIR := "user://test_saves"

func stable(d: Dictionary) -> Dictionary:
	# JSON reloads numbers as floats; normalize both sides using the same codec.
	var result: Dictionary = JSON.parse_string(JSON.stringify(d))
	result.erase("t")
	return result

func expect(condition: bool, description: String) -> void:
	print("  %s %s" % ["ok" if condition else "BAD", description])
	ok = condition and ok

func make_sim(seed_value: int) -> MooSim:
	var s := MooSim.new(seed_value)
	s.save_dir = SAVE_DIR
	simulations.append(s)
	return s

func _init() -> void:
	var expected := {}
	for i in range(1, 4):
		var s := make_sim(10 + i)
		s.delete_slot(i)
		s.start_slot(i)
		# Slots 1/2 hold different real played states; slot 3 finishes the career.
		var bot := MooBot.new(s)
		var limit := 90.0 * i if i < 3 else 3600.0
		while s.T < limit and not s.S.done:
			bot.tick(1.0 / 30.0)
			s.update(1.0 / 30.0)
		if i < 3:
			var unpaid := s.pads.filter(func(p): return p.paid < p.cost)
			expect(not unpaid.is_empty(), "slot %d has unfinished upgrades" % i)
			if not unpaid.is_empty():
				unpaid[0].paid = unpaid[0].cost / 2
			# Stable goods have arrived, matching snapshot's avail() contract.
			s.dispose()
			for m in s.live():
				if m.has("hopper"):
					m.hopper.n = 5 + i; m.hopper.inc = 0
				if m.has("tray"):
					m.tray.n = 11 + i; m.tray.inc = 0
				if m.has("box"):
					m.box.n = 8 + i; m.box.inc = 0
				if m.has("cash"):
					m.cash.n = 3 + i; m.cash.inc = 0; m.cash.val = 20 + i
					m.rep = 2.3 + i * 0.1
			s.player.stack = {"type": "corn" if i == 1 else "milk", "n": i + 2, "inc": 0}
			s.S.money = 1000 * i + 37
		else:
			expect(s.S.done, "career completed before saving slot 3")
		s.save(true)
		expected[i] = stable(s.snapshot())
		expect(expected[i] == stable(s.read_slot(i)), "slot %d writes every snapshot field" % i)
		s.dispose()
	for i in range(1, 4):
		var s := make_sim(99)
		expect(s.start_slot(i), "slot %d loads an existing save" % i)
		expect(stable(s.snapshot()) == expected[i], "slot %d restores every persisted field" % i)
		expect(s.belts.size() == 1, "slot %d reconstructs conveyor" % i)
		expect(s.S.done == (i == 3), "slot %d restores completion independently" % i)
		s.dispose()
	# Current-version keyed data must not promote a 90%-paid pad to finished.
	var migration := make_sim(101)
	migration.apply_state({"ver": 9, "paid": [], "pk": {"0:Corn conveyor": 45}})
	expect(migration.pads[0].paid == 45 and migration.belts.is_empty(), "v9 keyed save preserves unfinished payment")
	migration.dispose()
	# Current-slot deletion resets state without touching peers.
	var reset := make_sim(102)
	reset.start_slot(1)
	reset.delete_slot(1)
	var pristine := make_sim(103)
	expect(reset.cur_slot == 0 and stable(reset.snapshot()) == stable(pristine.snapshot()), "active slot deletion resets state")
	expect(reset.read_slot(1) == null, "deleted slot file is gone")
	for i in [2, 3]:
		expect(stable(reset.read_slot(i)) == expected[i], "deleting slot 1 leaves slot %d unchanged" % i)
	expect(not reset.start_slot(1), "deleted slot restarts as a new game")
	expect(stable(reset.snapshot()) == stable(pristine.snapshot()), "new slot inherits no previous inventory or purchases")
	reset.start_slot(3)
	var before := stable(reset.snapshot())
	reset.delete_slot(2)
	expect(reset.cur_slot == 3 and stable(reset.snapshot()) == before, "inactive slot deletion preserves active completed game")
	expect(stable(reset.read_slot(3)) == expected[3], "inactive deletion preserves completed save file")
	for i in range(1, 4):
		reset.delete_slot(i)
	for s in simulations:
		s.dispose()
	print(("PASS" if ok else "FAIL") + " save_slots")
	quit(0 if ok else 1)

extends SceneTree
## Persisted state round-trips, real gameplay, migration and slot reset isolation.
var ok := true
var simulations: Array = []
var test_save_dir := "user://test_saves_%d" % OS.get_process_id()

func stable(d: Dictionary) -> Dictionary:
	# JSON reloads numbers as floats; normalize both sides using the same codec.
	var result: Dictionary = JSON.parse_string(JSON.stringify(d))
	result.erase("t")
	return result

func expect(condition: bool, description: String) -> void:
	print("  %s %s" % ["ok" if condition else "BAD", description])
	ok = condition and ok

func make_sim(seed_value: int) -> MooSim:
	var s := MooEconomySim.new(seed_value)
	s.save_dir = test_save_dir
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
		var limit := 90.0 * i if i < 3 else 14400.0
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
			expect(s.S.ch == 2 and s.mod_by("C", 2).sold > 0 and s.mod_by("F", 2).sold > 0, "slot 3 reaches bread and pie sales through real play")
		s.save(true)
		expected[i] = stable(s.snapshot())
		if i == 3:
			expect(expected[i].bx.has("0B") and expected[i].bx.has("1C") and expected[i].bx.has("2B") and expected[i].bx.has("2E"), "completed save contains inventories in all three districts")
		expect(expected[i] == stable(s.read_slot(i)), "slot %d writes every snapshot field" % i)
		s.dispose()
	for i in range(1, 4):
		var s := make_sim(99)
		expect(s.start_slot(i), "slot %d loads an existing save" % i)
		expect(stable(s.snapshot()) == expected[i], "slot %d restores every persisted field" % i)
		expect(s.belts.size() == (4 if i == 3 else 1), "slot %d reconstructs purchased district conveyors" % i)
		expect(s.S.done == (i == 3), "slot %d restores completion independently" % i)
		s.dispose()
	# Current-version keyed data must not promote a 90%-paid pad to finished.
	var migration := make_sim(101)
	migration.apply_state({"ver": 9, "paid": [], "pk": {"0:Corn conveyor": 45}})
	expect(migration.pads[0].paid == 45 and migration.belts.is_empty(), "v9 keyed save preserves unfinished payment")
	migration.dispose()
	# The former one-chapter endpoint migrates to the newly available dairy.
	var old_completed := make_sim(104)
	old_completed.apply_state({"v": 1, "ver": 9, "ch": 0, "done": true,
		"pk": {"0:Buy the dairy": 800}, "money": 37,
		"bx": {"0B": {"h": 7, "t": 3}}, "hold": ["milk", 2]})
	expect(old_completed.S.ch == 1 and not old_completed.S.done, "old completed chapter 1 opens dairy rather than ending career")
	expect(old_completed.mod_by("B", 0).hopper.n == 7 and old_completed.mod_by("B", 0).tray.n == 3, "migration preserves original farm inventory")
	expect(old_completed.player.stack.type == "milk" and old_completed.S.money == 37, "migration preserves carried goods and wallet")
	expect(old_completed.pads.filter(func(p): return p.d == 1).all(func(p): return p.paid == 0), "migration does not grant dairy upgrades")
	old_completed.dispose()
	# The former two-chapter endpoint opens Baker while retaining earned upgrades.
	var old_dairy := make_sim(105)
	old_dairy.apply_state({"v": 1, "ver": 9, "ch": 1, "done": true,
		"pk": {"0:Buy the dairy":800, "1:Open a bakery":8400, "1:Dairy hand":840},
		"money":73, "bx":{"1C":{"h":6,"t":4}}, "hold":["cheese",3]})
	expect(old_dairy.S.ch == 2 and not old_dairy.S.done, "old completed dairy opens Baker rather than ending career")
	expect(old_dairy.S.money == 73 and old_dairy.player.stack.type == "cheese" and old_dairy.player.stack.n == 3, "dairy migration preserves wallet and carried cheese")
	expect(old_dairy.mod_by("C",1).hopper.n == 6 and old_dairy.mod_by("C",1).tray.n == 4, "dairy migration preserves press inventory")
	expect(old_dairy.helpers.any(func(h): return h.d == 1 and h.src_id == "B" and h.dst_id == "C"), "dairy migration preserves purchased helper")
	expect(old_dairy.pads.filter(func(p): return p.d == 2).all(func(p): return p.paid == 0), "dairy migration does not grant bakery upgrades")
	old_dairy.dispose()
	# Old array-only saves restore partial payments at either previous slice size.
	for old_size in [10, 22, 34]:
		var array_save := make_sim(106 + old_size)
		var payments: Array = []
		var economic := array_save.pads.filter(func(p): return not p.get("combat",false))
		for index in old_size: payments.append(economic[index].cost - 1)
		array_save.apply_state({"ver":9, "ch":0 if old_size == 10 else 1, "paid":payments, "money":123})
		var restored := true
		economic = array_save.pads.filter(func(p): return not p.get("combat",false))
		for index in economic.size():
			restored = restored and economic[index].paid == (payments[index] if index < old_size else 0)
		expect(restored and array_save.S.money == 123, "old %d-pad array restores exact partial prefix" % old_size)
		array_save.dispose()
	# Current-slot deletion resets state without touching peers.
	var reset := make_sim(102)
	reset.start_slot(1)
	reset.delete_slot(1)
	# S1 saves the seed-dependent threat RNG: compare fresh games with the same seed.
	var pristine := make_sim(102)
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
	DirAccess.remove_absolute(test_save_dir)
	print(("PASS" if ok else "FAIL") + " save_slots")
	quit(0 if ok else 1)

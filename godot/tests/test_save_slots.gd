extends SceneTree
## (3) Save round-trip across 3 isolated slots.
func _init() -> void:
	var dir := "user://test_saves"
	var sims := []
	var ok := true
	for i in range(1, 4):
		var s := MooSim.new(10 + i)
		s.save_dir = dir
		s.delete_slot(i)
		s.start_slot(i)
		s.S.money = 1000 * i
		for k in i:  # slot i buys its first i pads
			s.pads[k].paid = s.pads[k].cost
			s.apply_pad(s.pads[k], true)
		s.compute_reveal()
		s.save(true)
		sims.append(s.snapshot())
	for i in range(1, 4):
		var s := MooSim.new(99)
		s.save_dir = dir
		s.start_slot(i)
		var paid := s.pads.filter(func(p): return p.paid >= p.cost).size()
		var good: bool = s.S.money == 1000 * i and paid == i and s.belts.size() == 1 and (s.S.cap == 12) == (i >= 2)
		print("  slot %d: money=%d pads=%d belts=%d cap=%d %s" % [i, s.S.money, paid, s.belts.size(), s.S.cap, "ok" if good else "BAD"])
		ok = ok and good
		s.delete_slot(i)
	print(("PASS" if ok else "FAIL") + " save_slots")
	quit(0 if ok else 1)

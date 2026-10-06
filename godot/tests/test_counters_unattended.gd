extends SceneTree
## (2) Every counter sells unattended once its helpers are bought (player idle).
func _init() -> void:
	var sim := MooSim.new(2)
	sim.autosave = false
	sim.S.money = 100000
	for p in sim.pads:
		if p.fx != "gate" and p.fx != "price":
			p.paid = p.cost
			sim.apply_pad(p, true)
	sim.compute_reveal()
	sim.S.money = 0
	var start := {}
	for m in sim.mods:
		if m.type == "counter":
			start[m.id] = m.sold
	var t := 0.0
	while t < 300.0:
		sim.update(1.0 / 30.0); t += 1.0 / 30.0
	var ok := true
	for m in sim.mods:
		if m.type == "counter":
			var sold: int = m.sold - start[m.id]
			print("  %s sold %d unattended in 300s" % [m.name, sold])
			if sold <= 0: ok = false
	print(("PASS" if ok else "FAIL") + " counters_unattended")
	quit(0 if ok else 1)

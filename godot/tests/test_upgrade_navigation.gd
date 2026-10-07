extends SceneTree
## Exercise real completion actions against an independently rebuilt full nav mask.
var ok := true
func expect(value: bool, label: String) -> void:
	ok = ok and value
	print("  %s %s" % ["ok" if value else "BAD", label])
func compare(sim: MooSim, label: String) -> void:
	var incremental: PackedByteArray = sim.NAV.blk.duplicate()
	var public_incremental: PackedByteArray = sim.NAV.public_blk.duplicate()
	sim.build_nav()
	expect(incremental == sim.NAV.blk, label + " incremental grid matches full collision/fog rebuild")
	expect(public_incremental == sim.NAV.public_blk, label + " customer grid matches full field-avoidance rebuild")
func _init() -> void:
	var sim := MooSim.new(17)
	sim.autosave = false
	for i in range(43):
		var visible := sim.visible_pads()
		if visible.is_empty():
			expect(false, "all upgrades remain reachable")
			break
		var pad = visible[0]
		pad.paid = pad.cost - 1
		sim.S.money = 1
		var point := MooSim.ctr(pad)
		sim.player.x = point.x; sim.player.y = point.y
		sim.act()
		expect(pad.paid == pad.cost, pad.name + " finishes through normal payment action")
		expect(sim.shake_amt == 0 and sim.cam_focus == null, pad.name + " keeps upgrade camera steady")
		compare(sim, "%d:%s" % [pad.d, pad.name])
	sim.fresh_state()
	compare(sim, "new slot reset")
	sim.apply_state({"ver":9, "ch":0, "done":true, "pk":{"0:Chicken coop":150}})
	compare(sim, "old completed farm migration")
	sim.apply_state({"ver":9,"ch":1,"done":true,"pk":{"1:Open a bakery":8400}})
	compare(sim, "old completed dairy migration")
	sim.dispose()
	print(("PASS" if ok else "FAIL") + " upgrade_navigation")
	quit(0 if ok else 1)

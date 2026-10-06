extends SceneTree
## Customers route around crops; harvesters retain access; scenery is solid/stable.
const DT := 1.0 / 30.0
var ok := true

func expect(condition: bool, description: String) -> void:
	ok = condition and ok
	print("  %s %s" % ["ok" if condition else "BAD", description])

func in_field(sim: MooSim, entity: Dictionary) -> bool:
	for m in sim.live():
		if m.type == "field":
			var r = m.rect
			if entity.x >= r.x and entity.x <= r.x + r.w and entity.y >= r.y and entity.y <= r.y + r.h:
				return true
	return false

func run_customer(served: bool) -> void:
	var sim := MooSim.new(41 if served else 42)
	sim.autosave = false
	var field = sim.mod_by("A", 0)
	var counter = sim.mod_by("C", 0)
	# A genuine customer/queue fixture whose straight approach or exit cuts crops.
	var x: float = field.rect.x - 30 if served else field.rect.x + field.rect.w + 30
	var y: float = field.rect.y + 110
	var customer: Dictionary = sim.new_cust(x, y, counter)
	customer.want = 3
	customer.patience = 90.0 if served else 0.1
	counter.q.append(customer)
	for m in sim.live():
		if m.type == "counter": m.spawn = 100000.0
	counter.box.n = 12 if served else 0
	var slot := MooSim.q_slot(counter, 0)
	if served:
		expect(not sim.line_free(x, y, slot.x, slot.y, true), "served customer fixture would cut through corn with a straight approach")
	var crossed := false
	var departed := false
	var appeared_in_departures := false
	for i in range(3600):
		sim.update(DT)
		if in_field(sim, customer): crossed = true
		if sim.leaving.has(customer): appeared_in_departures = true
		if not counter.q.has(customer) and not sim.leaving.has(customer):
			departed = true
			break
	expect(not crossed, ("served" if served else "lost") + " customer feet avoid crop rectangles throughout approach/departure")
	expect(appeared_in_departures and departed, ("served" if served else "lost") + " customer completes departure and is removed")
	if served:
		expect(counter.sold > 0 and customer.got == customer.want, "routed customer reaches queue and buys actual stock")
	else:
		expect(counter.get("lost", 0) == 1 and counter.sold == 0, "impatient customer leaves without a sale")
	sim.dispose()

func forced_crossing() -> void:
	var sim := MooSim.new(44)
	sim.autosave = false
	var field = sim.mod_by("A", 0)
	var x: float = field.rect.x + field.rect.w / 2
	var above: float = field.rect.y - 30
	var below: float = field.rect.y + field.rect.h + 30
	for reverse in [false, true]:
		var y0: float = below if reverse else above
		var y1: float = above if reverse else below
		var customer: Dictionary = sim.new_cust(x, y0, sim.mod_by("C", 0))
		expect(not sim.line_free(x, y0, x, y1, true), "straight waypoint route across bed is blocked to customers")
		var crossed := false
		var arrived := false
		for i in range(1200):
			arrived = sim.walk_to(customer, x, y1, customer.speed, DT, true)
			if in_field(sim, customer): crossed = true
			if arrived: break
		expect(arrived and not crossed, "customer reaches opposite side of bed by walking around it (%s)" % ("up" if reverse else "down"))
	sim.dispose()

func scenery_and_harvester() -> void:
	var sim := MooSim.new(43)
	sim.autosave = false
	var original := []
	for c in sim.cells: original.append(c.decor.duplicate(true))
	var other := MooSim.new(99)
	var independent := []
	for c in other.cells: independent.append(c.decor.duplicate(true))
	expect(original == independent, "scenery geometry is independent of gameplay RNG seed")
	other.dispose()
	# Stage 1 contains modules in every cell; migrate to open wooded dairy/bakery margins.
	sim.apply_state({"ver":9,"ch":1,"done":true})
	var trees := 0
	var ponds := 0
	for c in sim.cells:
		if not c.on or c.mod != null: continue
		for obstacle in c.obs:
			if obstacle.has("c"):
				var circle = obstacle.c
				var entity := {"x": circle.x, "y": circle.y}
				expect(sim.blocked_at(entity.x, entity.y, 12), "tree trunk blocks collision at its center")
				sim.collide_player(entity)
				expect(not sim.blocked_at(entity.x, entity.y, 11.9), "player collision pushes feet clear of tree trunk")
				trees += 1
			elif obstacle.has("r") and not obstacle.get("fog", false):
				var rect = obstacle.r
				var entity := {"x": rect.x + rect.w / 2, "y": rect.y + rect.h / 2}
				expect(sim.blocked_at(entity.x, entity.y, 12), "pond interior blocks collision")
				sim.collide_player(entity)
				expect(not sim.blocked_at(entity.x, entity.y, 11.9), "player collision pushes feet clear of pond")
				ponds += 1
	expect(trees > 0 and ponds > 0, "revealed landscape contains solid trees and ponds")
	var field = sim.mod_by("A", 0)
	var center := MooSim.ctr(field.rect)
	var gx := sim.nav_gx(center.x)
	var gy := sim.nav_gy(center.y)
	expect(sim.nav_free(gx, gy) and not sim.nav_free(gx, gy, true), "crop center stays traversable for harvesting but closed to customers")
	var pad = sim.pads.filter(func(p): return p.d == 0 and p.fx == "feed")[0]
	pad.paid = pad.cost
	sim.apply_pad(pad, true)
	sim.compute_reveal()
	for i in range(2700): sim.update(DT)
	expect(sim.mod_by("B", 0).tray.n > 0, "real corn conveyor helper still harvests and produces milk")
	sim.fresh_state()
	var reset := []
	for c in sim.cells: reset.append(c.decor.duplicate(true))
	expect(original == reset, "slot reset preserves deterministic scenery")
	sim.dispose()

func _init() -> void:
	run_customer(true)
	run_customer(false)
	forced_crossing()
	scenery_and_harvester()
	print(("PASS" if ok else "FAIL") + " customer_routes")
	quit(0 if ok else 1)

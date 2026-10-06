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


class CountingSim extends MooSim:
	var path_requests := 0
	func find_path(ax: float, ay: float, bx: float, by: float, avoid_fields: bool = false):
		path_requests += 1
		return super.find_path(ax, ay, bx, by, avoid_fields)

func in_holder(sim: MooSim, entity: Dictionary) -> bool:
	for m in sim.live():
		if m.has("tray") and MooSim.in_r(entity, m.tray.rect, 25): return true
	return false

func holder_traffic(district: int, counter_id: String, served: bool) -> void:
	var sim := MooSim.new(50 + district)
	sim.autosave = false
	if district == 1: sim.apply_state({"ver":9,"ch":0,"done":true})
	var counter = sim.mod_by(counter_id, district)
	for m in sim.live():
		if m.type == "counter": m.spawn = 100000.0
	counter.spawn = 0.0
	counter.box.n = 12 if served else 0
	# Exercise actual spawn position, not a hand-placed safe customer.
	sim.update(DT)
	expect(counter.q.size() == 1, "holder-adjacent counter spawns a real customer")
	if counter.q.is_empty():
		sim.dispose()
		return
	var customer: Dictionary = counter.q[0]
	customer.want = 3
	customer.patience = 90.0
	counter.spawn = 100000.0
	var crossed: bool = in_holder(sim, customer)
	var expired := false
	var departed := false
	var saw_departure := false
	for i in range(3600):
		# Force the green waiting state only once the empty-shop queue is reached.
		if not served and customer.at and not expired:
			customer.wait = customer.patience - 0.01
			expect(customer.wait > customer.patience * 0.7, "empty shop customer reaches green impatient waiting state")
			expired = true
		sim.update(DT)
		if in_holder(sim, customer): crossed = true
		if sim.leaving.has(customer): saw_departure = true
		if not counter.q.has(customer) and not sim.leaving.has(customer):
			departed = true
			break
	var label := "%d:%s %s" % [district, counter_id, "served" if served else "lost"]
	expect(not crossed, label + " customer avoids every tray plus its 25px body margin at every frame")
	expect(saw_departure and departed, label + " customer completes departure and is removed")
	if served:
		expect(counter.sold > 0 and customer.got == customer.want, label + " buys actual stock")
	else:
		expect(expired and counter.get("lost",0) == 1 and counter.sold == 0, label + " leaves empty shop without a sale")
	sim.dispose()

func holder_access_and_failed_route() -> void:
	var sim := CountingSim.new(57)
	sim.autosave = false
	var barn = sim.mod_by("B", 0)
	var center := MooSim.ctr(barn.tray.rect)
	var gx := sim.nav_gx(center.x)
	var gy := sim.nav_gy(center.y)
	expect(sim.nav_free(gx, gy) and not sim.nav_free(gx, gy, true), "milk tray remains open to player/helper pickup and closed to public traffic")
	var customer: Dictionary = sim.new_cust(barn.tray.rect.x - 40, center.y, sim.mod_by("C",0))
	var arrived := false
	for i in range(120):
		arrived = sim.walk_to(customer, center.x, center.y, customer.speed, DT, true) or arrived
	expect(not arrived and not in_holder(sim, customer), "unreachable inside-holder customer target has no direct-motion fallback")
	expect(sim.path_requests == 1 and customer.path.is_empty(), "failed public route is cached instead of recomputed every frame")
	var safe: float = barn.tray.rect.y + barn.tray.rect.h + 40
	var reached_safe := false
	for i in range(900):
		reached_safe = sim.walk_to(customer, center.x, safe, customer.speed, DT, true)
		if reached_safe: break
	expect(reached_safe and sim.path_requests == 2, "changing failed target to safe sidewalk triggers one successful route")
	for reverse in [false,true]:
		var left: float = barn.tray.rect.x - 40
		var right: float = barn.tray.rect.x + barn.tray.rect.w + 30
		var x0: float = right if reverse else left
		var x1: float = left if reverse else right
		var crossing: Dictionary = sim.new_cust(x0,center.y,sim.mod_by("C",0))
		expect(not sim.line_free(x0,center.y,x1,center.y,true), "straight waypoint across milk holder is blocked to customers")
		var crossed := false
		var reached := false
		for i in range(1200):
			reached = sim.walk_to(crossing,x1,center.y,crossing.speed,DT,true)
			if in_holder(sim,crossing): crossed = true
			if reached: break
		expect(reached and not crossed, "customer walks around protected milk holder (%s)" % ("left" if reverse else "right"))
	barn.tray.n = 3
	sim.player.x = center.x; sim.player.y = center.y
	sim.act()
	expect(sim.player.stack.type == "milk" and sim.player.stack.n > 0, "player actually picks milk up from protected tray")
	for m in sim.live():
		if m.type == "counter": m.spawn = 100000.0
	barn.tray.n = 6; barn.tray.inc = 0
	sim.player.x = sim.mod_by("A",0).rect.x - 25
	sim.player.y = sim.mod_by("A",0).rect.y - 25
	var pad = sim.pads.filter(func(p): return p.d == 0 and p.fx == "helper" and p.f == "B" and p.t == "C")[0]
	pad.paid = pad.cost
	sim.apply_pad(pad,true)
	sim.compute_reveal()
	for i in range(1500): sim.update(DT)
	expect(sim.mod_by("C",0).box.n > 0, "real milk runner picks up protected tray stock and delivers it")
	sim.dispose()

func _init() -> void:
	run_customer(true)
	run_customer(false)
	for served in [true,false]:
		holder_traffic(0,"C",served)
		holder_traffic(1,"D",served)
	holder_access_and_failed_route()
	forced_crossing()
	scenery_and_harvester()
	print(("PASS" if ok else "FAIL") + " customer_routes")
	quit(0 if ok else 1)

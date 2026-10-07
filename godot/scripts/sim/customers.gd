extends RefCounted
## Customers system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func new_cust(x: float, y: float, m) -> Dictionary:
	return {"x": x, "y": y, "want": m.want[0] + sim.rng.randi() % (m.want[1] - m.want[0] + 1), "got": 0, "wait": 0.0, "serve": 0.0,
		"at": false, "happy": 0.0, "speed": 110.0, "face": 1, "walk": 0.0, "moving": false,
		"shirt": sim.pick(MooData.SHIRTS), "pants": sim.pick(MooData.PANTS), "skin": sim.pick(MooData.SKINS), "hair": sim.pick(MooData.HAIRS),
		"hat": sim.rng.randf() < 0.4, "item": m.item, "patience": MooSim.PATIENCE, "say": null, "leave": null, "path": null, "pathKey": ""}

static func q_slot(m, i: int) -> Dictionary:
	return {"x": m.ox + 340 - i * 54, "y": m.oy + 330}

## spawnFactor (L1045) in the morning, no night counters in ch.1.
static func spawn_factor(m) -> float:
	return 1.5 - (m.rep - 1) * 0.2

func pocket_cap(m) -> float:
	return maxf(60.0, m.price * 150.0)

func upd_counter(m, dt: float) -> void:
	m.spawn -= dt
	if m.spawn <= 0 and m.q.size() < 6:
		m.q.append(sim.new_cust(m.ox - 8, m.oy + 330, m))
		m.spawn = sim.rnd(2.4, 4.2) * spawn_factor(m)
	for i in m.q.size():
		var c = m.q[i]
		var s := q_slot(m, i)
		c.at = sim.walk_to(c, s.x, s.y, c.speed, dt, true)
		c.wait += dt
		if c.at:
			c.face = 1
	# customers who waited too long storm off (zombies come with the night port)
	for i in range(m.q.size() - 1, -1, -1):
		var c = m.q[i]
		if c.wait >= c.patience:
			m.q.remove_at(i)
			sim.customer_lost(c, m)
	if m.q.is_empty():
		return
	var c = m.q[0]
	if c.at:
		c.serve -= dt
		if c.serve <= 0 and c.got < c.want and MooSim.avail(m.box) > 0:
			c.serve = 0.16
			m.box.n -= 1
			c.got += 1
			c.wait = maxf(0.0, c.wait - 3)
			var f := sim.pile_pos(m.box.rect, m.box.n, m.item)
			sim.fly(m.item, f.x, f.y, func(): return {"x": c.x, "y": c.y - 30}, null, 0.2)
		if c.got >= c.want and c.serve <= 0:
			var late: bool = c.wait > c.patience * 0.7
			var amount := int(round(c.want * m.price * (1.5 if late else 1.0)))
			sim.payInto(m, amount, c.x, c.y - 30)
			sim.floaters.append({"x": c.x, "y": c.y - 84, "text": "+" + MooSim.fmt(amount), "t": 0.0})
			sim.on_served(m, c, amount)
			c.leave = {"x": m.ox + MooSim.CW + 40, "y": c.y}
			c.happy = 1.6
			if c.say == null and sim.rng.randf() < 0.45:
				sim.say(c, sim.pick(MooData.HAPPY_LINES), 2)
			sim.leaving.append(m.q.pop_front())

func customer_lost(c, m) -> void:
	m.rep = maxf(1.0, m.rep - 0.5)
	c.leave = {"x": m.ox - 8, "y": c.y}
	c.happy = 0.0
	sim.say(c, sim.pick(MooData.LOST_LINES), 1.8)
	sim.leaving.append(c)
	m.lost = m.get("lost", 0) + 1

func on_served(m, c, amount: int) -> void:
	m.sold += amount
	var quick: bool = c.wait < c.patience * 0.4
	m.rep = clampf(m.rep + (0.08 if quick else -0.04), 1, 5)

## payInto (L666): money goes into the shop's pocket; a full pocket spills coins.
func payInto(m, amount: int, fx: float, fy: float) -> void:
	var cash = m.cash
	var cap := sim.pocket_cap(m)
	var fits := int(maxf(0, minf(amount, cap - cash.val)))
	var spill := amount - fits
	if fits > 0:
		cash.val += fits
		var tokens := mini(int(ceil(fits / maxf(1, m.price))), 12)
		for k in tokens:
			cash.n += 1
			var idx: int = cash.n - 1
			sim.fly(cash.type, fx, fy, func(): return sim.pile_pos(cash.rect, idx, cash.type), cash, 0.25 + k * 0.03)
	if spill > 0:
		var n := mini(6, maxi(1, int(ceil(spill / maxf(1, m.price)))))
		var r = cash.rect
		for i in n:
			sim.ground.append({"x": r.x + r.w / 2 + sim.rnd(-70, 70), "y": r.y + r.h + sim.rnd(10, 50), "val": spill / n + (1 if i < spill % n else 0),
				"t": 30.0, "fx": r.x + r.w / 2, "fy": r.y, "ft": 0.0})
		if not m.has("spillWarn") or sim.T - m.spillWarn > 8:
			m.spillWarn = sim.T
			sim.toast("💸 " + m.name + " is overflowing — coins are spilling!", 2.4)


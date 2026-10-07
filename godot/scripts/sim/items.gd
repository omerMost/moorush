extends RefCounted
## Items system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func pile_pos(r, i: int, type: String) -> Dictionary:
	var sp = MooData.ITEMS[type]
	var cols: int = maxi(1, int(floor((r.w - 6) / sp.dx)))
	var rows: int = maxi(1, int(floor((r.h - 6) / sp.dy)))
	var per := cols * rows
	var layer := i / per
	var k := i % per
	var c := k % cols
	var rw := k / cols
	return {"x": r.x + 3 + sp.dx / 2.0 + c * sp.dx, "y": r.y + 3 + sp.dy + rw * sp.dy - layer * sp.h}

## Recover old count-only saves and test fixtures; live removals retain sparse IDs.
func ensure_layout(tray) -> void:
	if not tray.has("item_slots") or tray.item_slots.size() != tray.n:
		tray.item_slots = range(tray.n)
		tray.arriving_slots = range(maxi(0, tray.n - tray.inc), tray.n)

func visible_slots(tray) -> Array:
	sim.ensure_layout(tray)
	return tray.item_slots.filter(func(slot): return not slot in tray.arriving_slots)

## Reserve before launching so simultaneous producers cannot share a hole.
func reserve_slot(tray) -> int:
	sim.ensure_layout(tray)
	var slot := 0
	while slot in tray.item_slots:
		slot += 1
	tray.item_slots.append(slot)
	tray.arriving_slots.append(slot)
	tray.n += 1
	return slot

func stack_pos(e, i: int) -> Dictionary:
	var t: String = e.stack.type if e.stack.type != null else "milk"
	var sway: float = -e.get("lean", 0.0) * pow(i, 1.25) * 1.1 + (sin(sim.T * 9) * i * 0.12 if e.get("moving", false) else 0.0)
	return {"x": e.x + e.face * 12 + sway, "y": e.y - 22 - i * MooData.ITEMS[t].sh}

func fly(type: String, x: float, y: float, to: Callable, dest, dur: float = 0.24) -> Dictionary:
	if dest != null:
		dest.inc += 1
	var f := {"type": type, "x1": x, "y1": y, "to": to, "dest": dest, "t": 0.0, "dur": dur}
	sim.flyers.append(f)
	return f

## Rebase pending targets when visible goods leave the stack before arrival.
func stack_fly(item: String, source, e) -> void:
	var st = e.stack
	st.type = item
	st.n += 1
	sim.transfer_serial += 1
	var token := sim.transfer_serial
	if not st.has("pending_ids"): st.pending_ids = []
	st.pending_ids.append(token)
	var f := sim.fly(item, source.x, source.y, func(): return sim.stack_pos(e, MooSim.avail(st) + st.pending_ids.find(token)), st)
	f.stack_token = token

func take(src, e) -> bool:
	var slots := sim.visible_slots(src)
	var sp = MooData.ITEMS[src.type]
	var per: int = maxi(1, int(floor((src.rect.w - 6) / sp.dx))) * maxi(1, int(floor((src.rect.h - 6) / sp.dy)))
	var best := -1
	var best_distance := INF
	for slot in slots:
		var covered := false
		for other in src.item_slots:
			if other > slot and other % per == slot % per:
				covered = true
				break
		if covered: continue
		var pos := sim.pile_pos(src.rect, slot, src.type)
		var d := MooSim.dist(pos, e)
		if d < best_distance:
			best = slot
			best_distance = d
	if best < 0: return false
	var source := sim.pile_pos(src.rect, best, src.type)
	src.item_slots.erase(best)
	src.n -= 1
	sim.stack_fly(src.type, source, e)
	return true

func give(e, dst) -> void:
	var st = e.stack
	if MooSim.avail(st) <= 0: return
	var f := sim.stack_pos(e, MooSim.avail(st) - 1)
	st.n -= 1
	var idx: int = dst.n
	dst.n += 1
	sim.fly(st.type, f.x, f.y, func(): return sim.pile_pos(dst.rect, idx, dst.type), dst)
	if st.n <= 0:
		st.n = 0; st.type = null

func harvest(tile, e, item: String) -> void:
	tile.t = MooSim.REGROW
	sim.stack_fly(item, {"x": tile.x, "y": tile.y - 12}, e)

func give_belt(e, b) -> void:
	var st = e.stack
	if MooSim.avail(st) <= 0: return
	var f := sim.stack_pos(e, MooSim.avail(st) - 1)
	st.n -= 1
	sim.belt_push(b, f.x, f.y)
	if st.n <= 0:
		st.n = 0; st.type = null

func flight_pose(f) -> Dictionary:
	var p := clampf(f.t / f.dur, 0.0, 1.0)
	var target = f.to.call()
	var tossing: bool = f.get("kind", "") == "toss"
	var travel := p * p * (3.0 - 2.0 * p) if tossing else p
	var sink := smoothstep(0.7, 1.0, p) if tossing else 0.0
	return {"x": lerpf(f.x1, target.x, travel), "y": lerpf(f.y1, target.y, travel) - sin(PI * p) * (38.0 if tossing else 55.0), "scale": 1.0 - sink * 0.75, "alpha": 1.0 - sink}

func move_to(e, tx: float, ty: float, sp: float, dt: float) -> bool:
	var dx: float = tx - e.x
	var dy: float = ty - e.y
	var d := sqrt(dx * dx + dy * dy)
	if d < 1:
		e.moving = false
		return true
	var s := minf(d, sp * dt)
	e.x += dx / d * s
	e.y += dy / d * s
	e.moving = true
	e.walk += dt * 10
	if absf(dx) > 0.5:
		e.face = 1 if dx > 0 else -1
	return d < 4

# ===== player actions (L611-637) =====
func act() -> void:
	var p = sim.player
	var st = p.stack
	var can_take := func(t): return (st.type == null or st.type == t) and st.n < sim.S.cap
	var L := sim.live()
	for m in sim.mods:
		if not sim.active(m) or absf(m.ox + MooSim.CW / 2 - p.x) > MooSim.CW or absf(m.oy + MooSim.CHh / 2 - p.y) > MooSim.CHh:
			continue
		if m.type == "field" and can_take.call(m.item) and MooSim.in_r(p, m.rect, 20) and sim.dests_for(m.item, L, true).size():
			var nearest = null
			var nearest_distance := 40.0
			for t in m.tiles:
				var distance := MooSim.dist(t, p)
				if t.t <= 0 and distance < nearest_distance:
					nearest = t
					nearest_distance = distance
			if nearest != null:
				sim.harvest(nearest, p, m.item)
				sim.events.append({"kind": "pick"})
		if m.has("tray") and MooSim.in_r(p, m.tray.rect, 14) and MooSim.avail(m.tray) > 0:
			if can_take.call(m.tray.type):
				# hard-won fix: only pick up what something needs
				if sim.dests_for(m.tray.type, L, true).size():
					if sim.take(m.tray, p):
						sim.events.append({"kind": "pick"})
				elif st.type == null:
					sim.warn("Nobody needs " + MooSim.icon(m.tray.type) + " right now")
			elif st.type != null and st.type != m.tray.type:
				sim.warn("Hands full — drop the " + MooSim.icon(st.type) + " first")
		if m.type == "machine" and MooSim.in_r(p, m.inPad) and st.type != null and MooSim.avail(st) > 0:
			if st.type == m["in"]:
				if m.hopper.n < m.hopper.cap:
					sim.give(p, m.hopper)
					sim.events.append({"kind": "drop"})
			else:
				sim.warn(m.name + " needs " + MooSim.icon(m["in"]))
		if m.type == "counter":
			if MooSim.in_r(p, m.drop) and st.type != null and MooSim.avail(st) > 0:
				if st.type == m.item:
					if m.box.n < m.box.cap:
						sim.give(p, m.box)
						sim.events.append({"kind": "drop"})
				else:
					sim.warn(m.name + " sells " + MooSim.icon(m.item))
			var c = m.cash
			var a := MooSim.avail(c)
			if a > 0 and MooSim.in_r(p, c.rect, 8):
				var k := mini(a, maxi(1, int(ceil(a / 6.0))))
				var part: int = c.val if c.n <= k else int(round(c.val * k / float(c.n)))
				c.n -= k
				c.val -= part
				sim.S.money += part
				sim.events.append({"kind": "coin"})
				var f := sim.pile_pos(c.rect, c.n, c.type)
				sim.fly(c.type, f.x, f.y, func(): return {"x": p.x, "y": p.y - 60}, null, 0.2)
	for m in sim.mods:
		if m.has("bin") and sim.active(m) and st.type != null and MooSim.avail(st) > 0 and MooSim.in_r(p, m.bin, 22):
			var f := sim.stack_pos(p, MooSim.avail(st) - 1)
			st.n -= 1
			var c := {"x": m.bin.x + m.bin.w / 2.0, "y": m.bin.y + 8.0}
			var flight := sim.fly(st.type, f.x, f.y, func(): return c, null, 0.32)
			flight.kind = "toss"
			if st.n <= 0:
				st.n = 0; st.type = null
			break
	for b in sim.belts:
		if st.type == b.item and MooSim.avail(st) > 0 and MooSim.in_r(p, b.start) and MooSim.belt_room(b):
			sim.give_belt(p, b)
	for pd in sim.visible_pads():
		if not MooSim.in_r(p, pd):
			continue
		var w := sim.wallet()
		if w <= 0:
			continue
		var amt := mini(w, mini(pd.cost - pd.paid, maxi(1, int(ceil(pd.cost / 28.0)))))
		sim.S.money -= amt
		pd.paid += amt
		var px: float = p.x; var py: float = p.y
		sim.fly("coin", px, py - 60, func(): return {"x": pd.x + pd.w / 2, "y": pd.y + pd.h / 2 + 6}, null, 0.22)
		if pd.paid >= pd.cost:
			sim.apply_pad(pd, false)
			sim.compute_reveal()
			sim.save(true)
			sim.burst(MooSim.ctr(pd))
			sim.events.append({"kind": "unlock", "name": pd.name})
			if pd.fx != "gate":
				sim.toast("Unlocked: " + pd.name + "!", 2.4)

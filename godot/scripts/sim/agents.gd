extends RefCounted
## Agents system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func upd_machine(m, dt: float) -> void:
	var sp := 18.0 if m.kind == "cow" else (30.0 if m.kind == "hen" else 0.0)
	for u in m.units:
		if u.anim > 0:
			u.anim -= dt
		if sp > 0:
			if u.eat > 0:
				u.eat -= dt
			elif sim.move_to(u, u.tx, u.ty, sp, dt):
				u.idle -= dt
				if u.idle <= 0:
					u.tx = sim.rnd(m.area.x + 20, m.area.x + m.area.w - 20)
					u.ty = sim.rnd(m.area.y + 30, m.area.y + m.area.h)
					u.idle = sim.rnd(1, 3)
		u.timer += dt
		if u.timer >= m.period:
			if MooSim.avail(m.hopper) > 0 and m.tray.n < m.tray.cap:
				u.timer = 0.0
				m.hopper.n -= 1
				u.eat = 0.8 if sp > 0 else 0.0
				u.anim = 0.5
				var tr = m.tray
				var idx := sim.reserve_slot(tr)
				var flight := sim.fly(m.out, u.x, u.y - 24, func(): return sim.pile_pos(tr.rect, idx, m.out), tr, 0.45)
				flight.slot = idx
			else:
				u.timer = m.period

func upd_helper(h, dt: float) -> void:
	h.t -= dt
	if h.state == "from":
		if h.field != null:
			var st = h.stack
			var F = h.field.rect
			if st.n >= h.cap:
				h.state = "to"
				return
			var best = null
			var bd := 1e9
			for t in h.field.tiles:
				if t.t <= 0:
					var d := MooSim.dist(t, h)
					if d < bd:
						bd = d; best = t
			if not MooSim.in_r(h, F, 6):
				sim.walk_to(h, F.x + F.w / 2, F.y + F.h / 2, 150, dt)
				return
			if best == null:
				if st.n > 0:
					h.state = "to"
				return
			if sim.move_to(h, best.x, best.y + 8, 150, dt) and h.t <= 0:
				h.t = 0.12
				sim.harvest(best, h, h.field.item)
		elif sim.walk_to(h, h.fromStand.x, h.fromStand.y, 150, dt) and h.t <= 0:
			if MooSim.avail(h.from) > 0 and h.stack.n < h.cap:
				h.t = 0.1
				sim.take(h.from, h)
			elif h.stack.n > 0:
				h.state = "to"
	else:
		if sim.walk_to(h, h.toStand.x, h.toStand.y, 150, dt) and h.t <= 0:
			if h.stack.n > 0:
				if h.belt != null:
					if MooSim.belt_room(h.belt):
						h.t = 0.12
						sim.give_belt(h, h.belt)
				elif h.to.n < h.to.cap:
					h.t = 0.1
					sim.give(h, h.to)
			else:
				h.state = "from"

# ===== guide arrow (L755-793) =====

func nearest_ripe(item: String, list: Array):
	var b = null
	var bd := 1e9
	for m in list:
		if m.type == "field" and m.item == item:
			for t in m.tiles:
				if t.t <= 0:
					var d := MooSim.dist(t, sim.player)
					if d < bd:
						bd = d; b = t
	return b

func tray_source(item: String, list: Array, mn: int = 1):
	for m in list:
		if m.has("tray") and m.tray.type == item and MooSim.avail(m.tray) >= mn:
			return MooSim.ctr(m.tray.rect)
	return null

func any_source(item: String, list: Array):
	var s = sim.tray_source(item, list)
	if s != null:
		return s
	var t = sim.nearest_ripe(item, list)
	return {"x": t.x, "y": t.y} if t != null else null

## destsFor (L762): where an item can go right now (needRoom = there is space).
func dests_for(item: String, list: Array, need_room: bool) -> Array:
	var r := []
	for m in list:
		if m.type == "machine" and m["in"] == item and (not need_room or m.hopper.n < m.hopper.cap):
			r.append(MooSim.ctr(m.inPad))
		if m.type == "counter" and m.item == item and (not need_room or m.box.n < m.box.cap):
			r.append(MooSim.ctr(m.drop))
	return r

func nearest(list: Array):
	var b = null
	for x in list:
		if b == null or MooSim.dist(x, sim.player) < MooSim.dist(b, sim.player):
			b = x
	return b

func guide_target():
	var st = sim.player.stack
	var aff := sim.visible_pads().any(func(p): return sim.wallet() >= p.cost - p.paid)
	var sig := str(st.type) + str(st.n >= sim.S.cap) + str(sim.S.ch) + "|" + str(aff) + "|" + str(sim.S.tut.gary) + "|" + str(sim.S.get("gun",0)) + "|" + str(sim.gary_guide() != null)
	if sim.g_cache != null and sim.T < sim.g_cache.until and sim.g_cache.sig == sig and sim.g_cache.p != null and MooSim.dist(sim.player, sim.g_cache.p) > 25:
		return sim.g_cache.p
	var r = sim.guide_raw()
	sim.g_cache = {"p": r, "until": sim.T + 2.5, "sig": sig}
	return r

func guide_raw():
	var practice = sim.gary_guide()
	if practice != null: return practice
	for pad in sim.visible_pads():
		if pad.fx == "gun" and pad.d == sim.S.ch and sim.wallet() >= pad.cost-pad.paid: return MooSim.ctr(pad)
	var st = sim.player.stack
	var L := sim.live()
	var economic := sim.pads.filter(func(p): return p.d == sim.S.ch and not p.get("combat",false) and p.fx != "gate")
	var built := economic.filter(func(p): return p.paid >= p.cost).size()
	var base = sim.pads.filter(func(p): return p.d == sim.S.ch and p.fx == "gun")[0]
	# The arrow reserves earnings for the base after two production investments.
	# Upgrades get the same treatment once local automation is established.
	var reserve = base if base.paid < base.cost and built >= 2 else null
	if reserve == null and built >= (6 if sim.S.ch == 2 else economic.size()):
		for pad in sim.visible_pads():
			if pad.d == sim.S.ch and pad.get("combat",false): reserve = pad; break
	if reserve != null and sim.wallet() >= reserve.cost-reserve.paid: return MooSim.ctr(reserve)
	for p in sim.visible_pads():
		if reserve != null and p.d == sim.S.ch: continue
		if sim.wallet() >= p.cost - p.paid:
			return MooSim.ctr(p)
	if st.type == null:
		sim.g_mode = null
	elif st.n >= sim.S.cap:
		sim.g_mode = "deliver"
	if st.type != null and sim.g_mode != "deliver":
		var s = sim.any_source(st.type, L)
		if s != null and sim.dests_for(st.type, L, true).size():
			return s
		sim.g_mode = "deliver"
	if st.type != null:
		var d = sim.nearest(sim.dests_for(st.type, L, true))
		if d != null:
			return d
		for m in L:
			if m.type == "counter" and MooSim.avail(m.cash) > 0:
				return MooSim.ctr(m.cash.rect)
		var bins := []
		for m in L:
			if m.has("bin"):
				bins.append(MooSim.ctr(m.bin))
		var switch_task := L.any(func(m): return m.type == "counter" and m.item != st.type and m.box.n < m.box.cap - 3 and sim.tray_source(m.item, L, 4) != null)
		var wait = sim.nearest(sim.dests_for(st.type, L, false))
		if wait != null and not switch_task:
			return wait
		var nb = sim.nearest(bins)
		return nb if nb != null else wait
	for m in L:
		if m.type == "counter" and MooSim.avail(m.cash) > 0:
			return MooSim.ctr(m.cash.rect)
	var cs := L.filter(func(m): return m.type == "counter")
	cs.sort_custom(func(a, b): return a.box.n < b.box.n)
	for m in cs:
		if m.box.n < m.box.cap - 3:
			var s = sim.tray_source(m.item, L, 2)
			if s != null:
				return s
	var ms := L.filter(func(m): return m.type == "machine" and not sim.belts.any(func(b): return b.m == m))
	ms.sort_custom(func(a, b): return a.hopper.n < b.hopper.n)
	for m in ms:
		if m.hopper.n < m.hopper.cap - 4:
			var s = sim.any_source(m["in"], L)
			if s != null:
				return s
	for m in L:
		if m.type == "machine" and m.hopper.n < m.hopper.cap - 4:
			var t = sim.nearest_ripe(m["in"], L)
			if t != null:
				return {"x": t.x, "y": t.y}
	for m in cs:
		if m.box.n < m.box.cap:
			var s = sim.tray_source(m.item, L, 1)
			if s != null:
				return s
	return null

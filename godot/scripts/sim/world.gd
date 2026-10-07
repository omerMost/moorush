extends RefCounted
## World system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func mod_by(id: String, district: int = -1):
	if district < 0: district = int(sim.S.get("ch", 0))
	for m in sim.mods:
		if m.id == id and m.d == district:
			return m
	return null

func active(m) -> bool:
	return m.d <= int(sim.S.get("ch", 0)) and not m.locked and m.type != "gate" and not (m.type in ["garage", "armory", "bank"])

func live() -> Array:
	return sim.mods.filter(func(m): return sim.active(m))

# ===== build (L434-593) =====
func build_module(cfg: Dictionary, d: int) -> Dictionary:
	var o := MooSim.cell_xy(d, cfg.c, cfg.r)
	var ox := o.x
	var oy := o.y
	var m: Dictionary = cfg.duplicate(true)
	m.merge({"d": d, "key": str(d) + cfg.id, "ox": ox, "oy": oy, "cell": {"x": ox, "y": oy, "w": MooSim.CW, "h": MooSim.CHh},
		"locked": bool(cfg.get("locked", 0)), "slots": []}, true)
	match m.type:
		"field":
			m.rect = {"x": ox + 50, "y": oy + 70, "w": 300.0, "h": 250.0}
			m.tiles = []
			for r in 5:
				for c in 6:
					m.tiles.append({"x": m.rect.x + 25 + c * 50, "y": m.rect.y + 25 + r * 50, "t": 0.0})
			m.slots = [MooSim.P(ox + 365, oy + 60), MooSim.P(ox + 365, oy + 300)]
			m.bin = {"x": ox + 392, "y": oy + 142, "w": 52.0, "h": 52.0}
		"machine":
			var L: bool = str(m.get("side", "left")) == "left"
			m.side = "left" if L else "right"
			m.pen = {"x": ox + 160, "y": oy + 60, "w": 280.0, "h": 200.0} if L else {"x": ox + 30, "y": oy + 60, "w": 280.0, "h": 200.0}
			var pen = m.pen
			m.hopper = MooSim.box(m["in"], 24, {"x": pen.x + 8, "y": pen.y + pen.h - 62, "w": 58.0, "h": 54.0} if L else {"x": pen.x + pen.w - 66, "y": pen.y + pen.h - 62, "w": 58.0, "h": 54.0})
			m.inPad = {"x": ox + 30, "y": oy + 180, "w": 100.0, "h": 74.0} if L else {"x": ox + 340, "y": oy + 180, "w": 100.0, "h": 74.0}
			m.tray = MooSim.box(m.out, 60, {"x": ox + 170, "y": oy + 300, "w": 250.0, "h": 76.0} if L else {"x": ox + 50, "y": oy + 300, "w": 250.0, "h": 76.0})
			m.tray.item_slots = []
			m.tray.arriving_slots = []
			m.slots = [MooSim.P(ox + 35, oy + 60), MooSim.P(ox + 40, oy + 300)] if L else [MooSim.P(ox + 345, oy + 60), MooSim.P(ox + 335, oy + 300)]
			m.stand = {"x": m.tray.rect.x + m.tray.rect.w / 2.0, "y": oy + 402}
			m.units = []
			m.area = {"x": pen.x + 80, "y": pen.y + 20, "w": pen.w - 100, "h": pen.h - 30} if L else {"x": pen.x + 20, "y": pen.y + 20, "w": pen.w - 100, "h": pen.h - 30}
		"counter":
			m.bench = {"x": ox + 40, "y": oy + 210, "w": 340.0, "h": 36.0}
			m.box = MooSim.box(m.item, 40, {"x": ox + 60, "y": oy + 212, "w": 250.0, "h": 30.0})
			m.drop = {"x": ox + 60, "y": oy + 130, "w": 230.0, "h": 64.0}
			m.cash = MooSim.box("coin", 1000000000, {"x": ox + 305, "y": oy + 130, "w": 76.0, "h": 64.0})
			m.q = []
			m.spawn = 1.0
			m.slots = [MooSim.P(ox + 60, oy + 30), MooSim.P(ox + 180, oy + 30)]
			m.want = m.get("want", [2, 5])
			m.pay = "coin"
			m.rep = 3.0
			m.sold = 0
		"gate":
			m.pad = {"x": ox + 150, "y": oy + 170, "w": 170.0, "h": 120.0}
		"garage", "armory", "bank":
			for r in 2:
				for c in 3:
					m.slots.append({"x": ox + 40 + c * 135, "y": oy + 150 + r * 125, "w": 110.0, "h": 84.0})
			m.shop = {"x": ox + 130, "y": oy + 30, "w": 210.0, "h": 80.0}
	return m

func new_animal(a0) -> Dictionary:
	var a := {"x": 0.0, "y": 0.0, "tx": 0.0, "ty": 0.0, "idle": sim.rng.randf() * 2, "eat": 0.0, "timer": sim.rng.randf() * 2,
		"face": -1 if sim.rng.randf() < 0.5 else 1, "walk": 0.0, "spots": [], "moving": false, "anim": 0.0}
	a.x = sim.rnd(a0.x + 20, a0.x + a0.w - 20); a.tx = a.x
	a.y = sim.rnd(a0.y + 30, a0.y + a0.h); a.ty = a.y
	for i in 4:
		a.spots.append([sim.rnd(-18, 18), sim.rnd(-9, 6), sim.rnd(4, 8), sim.rnd(3, 6)])
	return a

func sync_units(m) -> void:
	if m.type != "machine":
		return
	while m.units.size() < m.n:
		m.units.append(sim.new_animal(m.area))

## belts (L516-536)
func make_belt(m):
	var src = null
	for f in sim.mods:
		if f.type == "field" and f.item == m["in"] and f.d == m.d and f.r == m.r and absi(f.c - m.c) == 1:
			src = f
	if src == null:
		return null
	var y: float = m.inPad.y + m.inPad.h / 2.0
	var left: bool = src.c < m.c
	var x1: float = src.rect.x + src.rect.w + 10 if left else src.rect.x - 10
	var x2: float = m.inPad.x + 8 if left else m.inPad.x + m.inPad.w - 8
	var b := {"m": m, "src": src, "x1": x1, "x2": x2, "y": y, "dir": signf(x2 - x1), "len": absf(x2 - x1), "items": [],
		"item": m["in"], "speed": 75.0, "gap": 20.0}
	b.start = {"x": x1 - 34, "y": y - 34, "w": 44.0, "h": 68.0} if left else {"x": x1 - 10, "y": y - 34, "w": 44.0, "h": 68.0}
	sim.belts.append(b)
	return b

static func belt_room(b) -> bool:
	return b.items.is_empty() or b.items[b.items.size() - 1] >= b.gap

func belt_push(b, from_x: float, from_y: float) -> void:
	b.items.append(0.0)
	sim.fly(b.item, from_x, from_y, func(): return {"x": b.x1, "y": b.y + 4}, null, 0.18)

func upd_belt(b, dt: float) -> void:
	for i in b.items.size():
		var lim: float = b.len if i == 0 else b.items[i - 1] - b.gap
		b.items[i] = minf(lim, b.items[i] + b.speed * dt)
	if b.items.size() and b.items[0] >= b.len and b.m.hopper.n < b.m.hopper.cap:
		b.items.pop_front()
		var h = b.m.hopper
		var idx: int = h.n
		h.n += 1
		sim.fly(b.item, b.x2, b.y, func(): return sim.pile_pos(h.rect, idx, h.type), h, 0.3)

func mk_helper(src, dst, i: int, belt) -> Dictionary:
	var H := {"x": 0.0, "y": 0.0, "walk": 0.0, "face": 1, "moving": false, "stack": {"type": null, "n": 0, "inc": 0},
		"state": "from", "t": 0.0, "look": MooData.HELPER_LOOKS[i % 3], "cap": 10, "path": null, "pathKey": "",
		"field": null, "from": null, "to": null, "belt": null, "src_id": src.id, "dst_id": dst.id, "d": src.d}
	if src.type == "field":
		H.field = src
		H.fromStand = MooSim.ctr(src.rect)
	else:
		H.from = src.tray
		H.fromStand = src.stand
	if belt != null:
		H.belt = belt
		H.toStand = {"x": belt.x1 - belt.dir * 22, "y": belt.y + 16}
		H.cap = 8
	elif dst.type == "machine":
		H.to = dst.hopper
		H.toStand = MooSim.ctr(dst.inPad)
	else:
		H.to = dst.box
		H.toStand = MooSim.ctr(dst.drop)
	H.x = H.fromStand.x
	H.y = H.fromStand.y
	return H

func pad_rect(p) -> Dictionary:
	if p.fx == "unlock":
		var t = sim.mod_by(p.t, p.d)
		return {"x": t.ox + MooSim.CW / 2 - 55, "y": t.oy + MooSim.CHh / 2 - 40, "w": 110.0, "h": 84.0}
	if p.fx == "gate":
		return sim.mod_by(p.m, p.d).pad
	return sim.mod_by(p.m, p.d).slots[p.s]

func build_world() -> void:
	sim.NAV.blk = PackedByteArray()
	sim.NAV.public_blk = PackedByteArray()
	sim.mods = []; sim.pads = []; sim.helpers = []; sim.belts = []; sim.leaving = []; sim.flyers = []; sim.cells = []; sim.ground = []
	sim.floaters = []; sim.sparks = []
	var k := 0
	for district in range(MooData.STAGE_COUNT):
		var content := MooData.stage_at(district)
		for cfg in content.mods:
			sim.mods.append(sim.build_module(cfg, district))
		for p in content.pads:
			var pd: Dictionary = p.duplicate(true)
			pd.merge({"d": district, "k": k, "paid": 0, "cur": "coin"}, true)
			sim.pads.append(pd)
			k += 1
		for r in 3:
			for c in 3:
				var o := MooSim.cell_xy(district, c, r)
				sim.cells.append({"d": district, "c": c, "r": r, "x": o.x, "y": o.y, "w": MooSim.CW, "h": MooSim.CHh, "mod": null, "fog": 1.0, "on": false,
					"seed": (district * 27 + r * 9 + c) * 7919, "obs": [], "decor": []})
	for m in sim.mods:
		for c in sim.cells:
			if c.d == m.d and c.c == m.c and c.r == m.r:
				c.mod = m
	for c in sim.cells:
		if c.mod == null: sim.make_decor(c)
	for p in sim.pads:
		p.merge(sim.pad_rect(p), true)
	for m in sim.mods:
		sim.sync_units(m)
	var a = sim.mod_by("A", 0)
	sim.player = {"x": a.rect.x + a.rect.w / 2, "y": a.rect.y + a.rect.h + 30, "walk": 0.0, "face": 1, "moving": false,
		"stack": {"type": null, "n": 0, "inc": 0}, "vx": 0.0, "pinned": 0.0, "say": null}
	# Grid spans every implemented district at its prototype map position.
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for district in range(MooData.STAGE_COUNT):
		var origin := MooSim.cell_xy(district, 0, 0)
		low = low.min(origin)
		high = high.max(origin + Vector2(MooSim.DW, MooSim.DH))
	sim.NAV.ox = low.x - MooSim.GAP
	sim.NAV.oy = low.y - MooSim.GAP
	sim.NAV.nx = int(ceil((high.x - low.x + 2 * MooSim.GAP) / sim.NAV.s))
	sim.NAV.ny = int(ceil((high.y - low.y + 2 * MooSim.GAP) / sim.NAV.s))

func apply_pad(p, from_load: bool) -> void:
	var m = sim.mod_by(p.m, p.d) if p.has("m") else null
	match p.fx:
		"feed":
			var b = sim.make_belt(m)
			if b != null:
				sim.helpers.append(sim.mk_helper(b.src, m, sim.helpers.size(), b))
		"cap":
			sim.S.cap = maxi(sim.S.cap, p.v)
		"more":
			m.n += p.v
			sim.sync_units(m)
		"price":
			m.price = int(round(m.price * p.v))
		"unlock":
			var t = sim.mod_by(p.t, p.d)
			t.locked = false
			sim.sync_units(t)
		"helper":
			sim.helpers.append(sim.mk_helper(sim.mod_by(p.f, p.d), sim.mod_by(p.t, p.d), sim.helpers.size(), null))
		"gate":
			if p.d < MooData.STAGE_COUNT - 1:
				var entered: bool = p.d + 1 > sim.S.ch
				sim.S.ch = maxi(sim.S.ch, p.d + 1)
				if entered and not from_load: sim.reset_clock()
				sim.stage = MooData.stage_at(sim.S.ch)
				sim.S.done = false
				if not from_load:
					sim.compute_reveal()
					sim.travel_to(p.d + 1)
					sim.toast("Chapter %d · %s! %s" % [sim.S.ch + 1, sim.stage.title, sim.stage.intro], 5.0)
			else:
				sim.S.done = true
				if not from_load: sim.toast("🛒 Supermarket bought! Chapter 3 complete — more chapters coming soon.", 5.0)
			if not from_load: sim.events.append({"kind": "gate"})

func visible_pads() -> Array:
	var out := []
	var counts := {}
	for p in sim.pads:
		if p.d > sim.S.ch or p.paid >= p.cost:
			continue
		var n := int(counts.get(p.d, 0))
		if n < 3:
			out.append(p)
			counts[p.d] = n + 1
	return out

func wallet() -> int:
	return sim.S.money

## reveal (L577-591)
func compute_reveal() -> void:
	var vp := sim.visible_pads()
	for c in sim.cells:
		var on := false
		var m = c.mod
		if c.d > sim.S.ch:
			c.on = false
			continue
		if m != null:
			if m.type == "gate":
				on = sim.pads.any(func(p): return p.d == c.d and p.fx == "gate" and (p.paid >= p.cost or vp.has(p)))
			elif m.type in ["armory", "bank", "garage"]:
				on = true
			else:
				on = not m.locked or vp.any(func(p): return p.d == c.d and p.fx == "unlock" and p.t == m.id)
		else:
			on = sim.cells.any(func(k): return k.d == c.d and k.mod != null and sim.active(k.mod) and absi(k.c - c.c) + absi(k.r - c.r) == 1)
		c.on = on
	var x0 := 1e9; var y0 := 1e9; var x1 := -1e9; var y1 := -1e9
	for c in sim.cells:
		if c.on:
			x0 = minf(x0, c.x); y0 = minf(y0, c.y); x1 = maxf(x1, c.x + c.w); y1 = maxf(y1, c.y + c.h)
	sim.target_bounds = {"x0": x0, "y0": y0, "x1": x1, "y1": y1}
	sim.refresh_obstacles()

class_name MooSim
extends RefCounted
## The whole chapter-1 simulation, ported from prototype/index.html (frozen spec).
## Pure logic, no nodes: the view (world_view.gd / hud.gd) draws it and the
## headless bots (tests/) drive it. Section comments name the prototype lines.
## Entities are Dictionaries on purpose, so the code reads 1:1 against the JS.

# ===== world geometry (L371-376) =====
const SPEED := 230.0
const REGROW := 6.0
const CW := 470.0
const CHh := 420.0
const DW := CW * 3.0
const DH := CHh * 3.0
const GAP := 90.0
const MAR := 70.0
const DPOS := [[0, 2], [1, 2], [2, 2], [2, 1], [1, 1], [0, 1], [0, 0], [1, 0], [2, 0]]
const W := MAR * 2.0 + 3.0 * DW + 2.0 * GAP
const ACT_TICK := 0.06
const SAVE_EVERY := 4.0
const PATIENCE := 33.0  # decorateCust (L1039), sunny day, no VIP

static func cell_xy(d: int, c: int, r: int) -> Vector2:
	return Vector2(MAR + DPOS[d][0] * (DW + GAP) + c * CW, MAR + DPOS[d][1] * (DH + GAP) + r * CHh)

# ===== state (L427-431) =====
var S := {}
var mods: Array = []
var pads: Array = []
var cells: Array = []
var helpers: Array = []
var belts: Array = []
var leaving: Array = []
var flyers: Array = []
var floaters: Array = []
var toasts: Array = []
var sparks: Array = []
var ground: Array = []
var player := {}
var T := 0.0
var act_t := 0.0
var save_t := 0.0
var warn_t := 0.0
var target_bounds := {"x0": 0.0, "y0": 0.0, "x1": W, "y1": 4000.0}
var bounds = null
var NAV := {"s": 20, "ox": 0.0, "oy": 0.0, "nx": 0, "ny": 0, "blk": PackedByteArray()}
var stage: Dictionary
var rng := RandomNumberGenerator.new()
var no_clip := false

## Input: the view writes move_in (joystick/keys, already magnitude-scaled);
## bots write test_in (L723 testIn). test_in wins, like the prototype.
var move_in := Vector2.ZERO
var test_in := Vector2.ZERO

## Camera hints for the view.
var cam_focus = null  # {x,y,t} (focusOn L1347)
var shake_amt := 0.0
var saved_flash := 0.0
var events: Array = []  # [{kind, ...}] drained by the view (sound / juice hooks)

## Saves (L2064): 3 isolated slots, one JSON file each.
const SLOTS := 3
var save_dir := "user://"
var cur_slot := 0
var autosave := true

var g_cache = null

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	stage = MooData.stage0()
	fresh_state()

# ===== helpers (L378-385) =====
func rnd(a: float, b: float) -> float:
	return a + rng.randf() * (b - a)

func pick(a: Array):
	return a[rng.randi() % a.size()]

static func in_r(p, r, m: float = 0.0) -> bool:
	return p.x > r.x - m and p.x < r.x + r.w + m and p.y > r.y - m and p.y < r.y + r.h + m

static func ctr(r) -> Dictionary:
	return {"x": r.x + r.w / 2.0, "y": r.y + r.h / 2.0}

static func avail(b) -> int:
	return b.n - b.inc

static func dist(a, b) -> float:
	return Vector2(a.x - b.x, a.y - b.y).length()

static func fmt(n: float) -> String:
	var v := int(floor(n))
	if v >= 1000000:
		return _trim(snappedf(v / 1e6, 1.0 if v >= 10000000 else 0.1)) + "M"
	if v >= 10000:
		return _trim(snappedf(v / 1e3, 1.0 if v >= 100000 else 0.1)) + "k"
	return str(v)

static func _trim(f: float) -> String:
	var s := str(f)
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return s

## hash (L1548), 32-bit unsigned emulation.
static func hash01(n: int) -> float:
	const M := 0xFFFFFFFF
	n &= M
	n = (n ^ 61) ^ (n >> 16)
	n = (n + (n << 3)) & M
	n = n ^ (n >> 4)
	n = (n * 0x27d4eb2d) & M
	n = n ^ (n >> 15)
	return float(n) / 4294967296.0

static func box(type: String, cap: int, rect: Dictionary) -> Dictionary:
	return {"type": type, "cap": cap, "rect": rect, "n": 0, "inc": 0, "val": 0}

static func P(x: float, y: float, w: float = 90.0, h: float = 70.0) -> Dictionary:
	return {"x": x, "y": y, "w": w, "h": h}

func mod_by(id: String):
	for m in mods:
		if m.id == id:
			return m
	return null

func active(m) -> bool:
	return not m.locked and m.type != "gate" and not (m.type in ["garage", "armory", "bank"])

func live() -> Array:
	return mods.filter(func(m): return active(m))

# ===== items (L395-418) =====
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

# ===== build (L434-593) =====
func build_module(cfg: Dictionary, d: int) -> Dictionary:
	var o := cell_xy(d, cfg.c, cfg.r)
	var ox := o.x
	var oy := o.y
	var m: Dictionary = cfg.duplicate(true)
	m.merge({"d": d, "key": str(d) + cfg.id, "ox": ox, "oy": oy, "cell": {"x": ox, "y": oy, "w": CW, "h": CHh},
		"locked": bool(cfg.get("locked", 0)), "slots": []}, true)
	match m.type:
		"field":
			m.rect = {"x": ox + 50, "y": oy + 70, "w": 300.0, "h": 250.0}
			m.tiles = []
			for r in 5:
				for c in 6:
					m.tiles.append({"x": m.rect.x + 25 + c * 50, "y": m.rect.y + 25 + r * 50, "t": 0.0})
			m.slots = [P(ox + 365, oy + 60), P(ox + 365, oy + 300)]
			m.bin = {"x": ox + 392, "y": oy + 142, "w": 52.0, "h": 52.0}
		"machine":
			var L: bool = str(m.get("side", "left")) == "left"
			m.side = "left" if L else "right"
			m.pen = {"x": ox + 160, "y": oy + 60, "w": 280.0, "h": 200.0} if L else {"x": ox + 30, "y": oy + 60, "w": 280.0, "h": 200.0}
			var pen = m.pen
			m.hopper = box(m["in"], 24, {"x": pen.x + 8, "y": pen.y + pen.h - 62, "w": 58.0, "h": 54.0} if L else {"x": pen.x + pen.w - 66, "y": pen.y + pen.h - 62, "w": 58.0, "h": 54.0})
			m.inPad = {"x": ox + 30, "y": oy + 180, "w": 100.0, "h": 74.0} if L else {"x": ox + 340, "y": oy + 180, "w": 100.0, "h": 74.0}
			m.tray = box(m.out, 60, {"x": ox + 170, "y": oy + 300, "w": 250.0, "h": 76.0} if L else {"x": ox + 50, "y": oy + 300, "w": 250.0, "h": 76.0})
			m.slots = [P(ox + 35, oy + 60), P(ox + 40, oy + 300)] if L else [P(ox + 345, oy + 60), P(ox + 335, oy + 300)]
			m.stand = {"x": m.tray.rect.x + m.tray.rect.w / 2.0, "y": oy + 402}
			m.units = []
			m.area = {"x": pen.x + 80, "y": pen.y + 20, "w": pen.w - 100, "h": pen.h - 30} if L else {"x": pen.x + 20, "y": pen.y + 20, "w": pen.w - 100, "h": pen.h - 30}
		"counter":
			m.bench = {"x": ox + 40, "y": oy + 210, "w": 340.0, "h": 36.0}
			m.box = box(m.item, 40, {"x": ox + 60, "y": oy + 212, "w": 250.0, "h": 30.0})
			m.drop = {"x": ox + 60, "y": oy + 130, "w": 230.0, "h": 64.0}
			m.cash = box("coin", 1000000000, {"x": ox + 305, "y": oy + 130, "w": 76.0, "h": 64.0})
			m.q = []
			m.spawn = 1.0
			m.slots = [P(ox + 60, oy + 30), P(ox + 180, oy + 30)]
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
	var a := {"x": 0.0, "y": 0.0, "tx": 0.0, "ty": 0.0, "idle": rng.randf() * 2, "eat": 0.0, "timer": rng.randf() * 2,
		"face": -1 if rng.randf() < 0.5 else 1, "walk": 0.0, "spots": [], "moving": false, "anim": 0.0}
	a.x = rnd(a0.x + 20, a0.x + a0.w - 20); a.tx = a.x
	a.y = rnd(a0.y + 30, a0.y + a0.h); a.ty = a.y
	for i in 4:
		a.spots.append([rnd(-18, 18), rnd(-9, 6), rnd(4, 8), rnd(3, 6)])
	return a

func sync_units(m) -> void:
	if m.type != "machine":
		return
	while m.units.size() < m.n:
		m.units.append(new_animal(m.area))

## belts (L516-536)
func make_belt(m):
	var src = null
	for f in mods:
		if f.type == "field" and f.item == m["in"] and f.r == m.r and absi(f.c - m.c) == 1:
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
	belts.append(b)
	return b

static func belt_room(b) -> bool:
	return b.items.is_empty() or b.items[b.items.size() - 1] >= b.gap

func belt_push(b, from_x: float, from_y: float) -> void:
	b.items.append(0.0)
	fly(b.item, from_x, from_y, func(): return {"x": b.x1, "y": b.y + 4}, null, 0.18)

func upd_belt(b, dt: float) -> void:
	for i in b.items.size():
		var lim: float = b.len if i == 0 else b.items[i - 1] - b.gap
		b.items[i] = minf(lim, b.items[i] + b.speed * dt)
	if b.items.size() and b.items[0] >= b.len and b.m.hopper.n < b.m.hopper.cap:
		b.items.pop_front()
		var h = b.m.hopper
		var idx: int = h.n
		h.n += 1
		fly(b.item, b.x2, b.y, func(): return pile_pos(h.rect, idx, h.type), h, 0.3)

func mk_helper(src, dst, i: int, belt) -> Dictionary:
	var H := {"x": 0.0, "y": 0.0, "walk": 0.0, "face": 1, "moving": false, "stack": {"type": null, "n": 0, "inc": 0},
		"state": "from", "t": 0.0, "look": MooData.HELPER_LOOKS[i % 3], "cap": 10, "path": null, "pathKey": "",
		"field": null, "from": null, "to": null, "belt": null, "src_id": src.id, "dst_id": dst.id}
	if src.type == "field":
		H.field = src
		H.fromStand = ctr(src.rect)
	else:
		H.from = src.tray
		H.fromStand = src.stand
	if belt != null:
		H.belt = belt
		H.toStand = {"x": belt.x1 - belt.dir * 22, "y": belt.y + 16}
		H.cap = 8
	elif dst.type == "machine":
		H.to = dst.hopper
		H.toStand = ctr(dst.inPad)
	else:
		H.to = dst.box
		H.toStand = ctr(dst.drop)
	H.x = H.fromStand.x
	H.y = H.fromStand.y
	return H

func pad_rect(p) -> Dictionary:
	if p.fx == "unlock":
		var t = mod_by(p.t)
		return {"x": t.ox + CW / 2 - 55, "y": t.oy + CHh / 2 - 40, "w": 110.0, "h": 84.0}
	if p.fx == "gate":
		return mod_by(p.m).pad
	return mod_by(p.m).slots[p.s]

func build_world() -> void:
	mods = []; pads = []; helpers = []; belts = []; leaving = []; flyers = []; cells = []; ground = []
	floaters = []; sparks = []
	for cfg in stage.mods:
		mods.append(build_module(cfg, 0))
	var k := 0
	for p in stage.pads:
		var pd: Dictionary = p.duplicate(true)
		pd.merge({"d": 0, "k": k, "paid": 0, "cur": "coin"}, true)
		pads.append(pd)
		k += 1
	for r in 3:
		for c in 3:
			var o := cell_xy(0, c, r)
			cells.append({"d": 0, "c": c, "r": r, "x": o.x, "y": o.y, "w": CW, "h": CHh, "mod": null, "fog": 1.0, "on": false,
				"seed": (0 * 27 + r * 9 + c) * 7919, "obs": []})
	for m in mods:
		for c in cells:
			if c.c == m.c and c.r == m.r:
				c.mod = m
	for p in pads:
		p.merge(pad_rect(p), true)
	for m in mods:
		sync_units(m)
	var a = mod_by("A")
	player = {"x": a.rect.x + a.rect.w / 2, "y": a.rect.y + a.rect.h + 30, "walk": 0.0, "face": 1, "moving": false,
		"stack": {"type": null, "n": 0, "inc": 0}, "vx": 0.0, "pinned": 0.0, "say": null}
	# nav grid covers the district plus a GAP margin (provisional: the prototype grids the whole map)
	var o0 := cell_xy(0, 0, 0)
	NAV.ox = o0.x - GAP
	NAV.oy = o0.y - GAP
	NAV.nx = int(ceil((DW + 2 * GAP) / NAV.s))
	NAV.ny = int(ceil((DH + 2 * GAP) / NAV.s))

func apply_pad(p, from_load: bool) -> void:
	var m = mod_by(p.m) if p.has("m") else null
	match p.fx:
		"feed":
			var b = make_belt(m)
			if b != null:
				helpers.append(mk_helper(b.src, m, helpers.size(), b))
		"cap":
			S.cap = maxi(S.cap, p.v)
		"more":
			m.n += p.v
			sync_units(m)
		"price":
			m.price = int(round(m.price * p.v))
		"unlock":
			var t = mod_by(p.t)
			t.locked = false
			sync_units(t)
		"helper":
			helpers.append(mk_helper(mod_by(p.f), mod_by(p.t), helpers.size(), null))
		"gate":
			S.done = true
			if not from_load:
				toast("🏡 You bought the dairy! Chapter 1 complete!", 4.0)
				events.append({"kind": "gate"})

func visible_pads() -> Array:
	var out := []
	var n := 0
	for p in pads:
		if p.paid >= p.cost:
			continue
		if n < 3:
			out.append(p)
			n += 1
	return out

func wallet() -> int:
	return S.money

## reveal (L577-591)
func compute_reveal() -> void:
	var vp := visible_pads()
	for c in cells:
		var on := false
		var m = c.mod
		if m != null:
			if m.type == "gate":
				on = pads.any(func(p): return p.fx == "gate" and (p.paid >= p.cost or vp.has(p)))
			elif m.type in ["armory", "bank", "garage"]:
				on = true
			else:
				on = not m.locked or vp.any(func(p): return p.fx == "unlock" and p.t == m.id)
		else:
			on = cells.any(func(k): return k.mod != null and active(k.mod) and absi(k.c - c.c) + absi(k.r - c.r) == 1)
		c.on = on
	var x0 := 1e9; var y0 := 1e9; var x1 := -1e9; var y1 := -1e9
	for c in cells:
		if c.on:
			x0 = minf(x0, c.x); y0 = minf(y0, c.y); x1 = maxf(x1, c.x + c.w); y1 = maxf(y1, c.y + c.h)
	target_bounds = {"x0": x0, "y0": y0, "x1": x1, "y1": y1}
	refresh_obstacles()

# ===== transfers (L594-608) =====
func stack_pos(e, i: int) -> Dictionary:
	var t: String = e.stack.type if e.stack.type != null else "milk"
	return {"x": e.x + e.face * 12, "y": e.y - 22 - i * MooData.ITEMS[t].sh}

func fly(type: String, x: float, y: float, to: Callable, dest, dur: float = 0.24) -> void:
	if dest != null:
		dest.inc += 1
	flyers.append({"type": type, "x1": x, "y1": y, "to": to, "dest": dest, "t": 0.0, "dur": dur})

func take(src, e) -> void:
	src.n -= 1
	var st = e.stack
	st.type = src.type
	st.n += 1
	var idx: int = st.n - 1
	var f := pile_pos(src.rect, src.n, src.type)
	fly(src.type, f.x, f.y, func(): return stack_pos(e, idx), st)

func give(e, dst) -> void:
	var st = e.stack
	st.n -= 1
	var idx: int = dst.n
	dst.n += 1
	var f := stack_pos(e, st.n)
	fly(st.type, f.x, f.y, func(): return pile_pos(dst.rect, idx, dst.type), dst)
	if st.n <= 0:
		st.n = 0; st.type = null

func harvest(tile, e, item: String) -> void:
	tile.t = REGROW
	var st = e.stack
	st.type = item
	st.n += 1
	var idx: int = st.n - 1
	fly(item, tile.x, tile.y - 12, func(): return stack_pos(e, idx), st)

func give_belt(e, b) -> void:
	var st = e.stack
	st.n -= 1
	var f := stack_pos(e, st.n)
	belt_push(b, f.x, f.y)
	if st.n <= 0:
		st.n = 0; st.type = null

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

func toast(t: String, dur: float = 2.2) -> void:
	if toasts.size() and toasts[toasts.size() - 1].text == t:
		return
	toasts.append({"text": t, "t": 0.0, "dur": dur})
	if toasts.size() > 2:
		toasts.pop_front()

func warn(t: String) -> void:
	if warn_t <= 0:
		toast(t, 1.6)
		warn_t = 2.5
		events.append({"kind": "warn"})

func burst(c, n: int = 28) -> void:
	for i in n:
		var a := rng.randf() * TAU
		var v := rnd(80, 230)
		sparks.append({"x": c.x, "y": c.y, "vx": cos(a) * v, "vy": sin(a) * v - 120, "t": 0.0,
			"col": pick(["#ffd54a", "#7ed957", "#ffffff", "#ff9f43", "#4fc3f7"])})

func say(e, text: String, dur: float = 1.8) -> void:
	e.say = {"text": text, "t": dur}

static func icon(t: String) -> String:
	return MooData.ITEMS[t].e if MooData.ITEMS.has(t) else t

# ===== player actions (L611-637) =====
func act() -> void:
	var p = player
	var st = p.stack
	var can_take := func(t): return (st.type == null or st.type == t) and st.n < S.cap
	var L := live()
	for m in mods:
		if not active(m) or absf(m.ox + CW / 2 - p.x) > CW or absf(m.oy + CHh / 2 - p.y) > CHh:
			continue
		if m.type == "field" and can_take.call(m.item) and in_r(p, m.rect, 20) and dests_for(m.item, L, true).size():
			for t in m.tiles:
				if t.t <= 0 and Vector2(t.x - p.x, t.y - p.y).length() < 40:
					harvest(t, p, m.item)
					events.append({"kind": "pick"})
					break
		if m.has("tray") and in_r(p, m.tray.rect, 14) and avail(m.tray) > 0:
			if can_take.call(m.tray.type):
				# hard-won fix: only pick up what something needs
				if dests_for(m.tray.type, L, true).size():
					take(m.tray, p)
					events.append({"kind": "pick"})
				elif st.type == null:
					warn("Nobody needs " + icon(m.tray.type) + " right now")
			elif st.type != null and st.type != m.tray.type:
				warn("Hands full — drop the " + icon(st.type) + " first")
		if m.type == "machine" and in_r(p, m.inPad) and st.type != null:
			if st.type == m["in"]:
				if m.hopper.n < m.hopper.cap:
					give(p, m.hopper)
					events.append({"kind": "drop"})
			else:
				warn(m.name + " needs " + icon(m["in"]))
		if m.type == "counter":
			if in_r(p, m.drop) and st.type != null:
				if st.type == m.item:
					if m.box.n < m.box.cap:
						give(p, m.box)
						events.append({"kind": "drop"})
				else:
					warn(m.name + " sells " + icon(m.item))
			var c = m.cash
			var a := avail(c)
			if a > 0 and in_r(p, c.rect, 8):
				var k := mini(a, maxi(1, int(ceil(a / 6.0))))
				var part: int = c.val if c.n <= k else int(round(c.val * k / float(c.n)))
				c.n -= k
				c.val -= part
				S.money += part
				events.append({"kind": "coin"})
				var f := pile_pos(c.rect, c.n, c.type)
				fly(c.type, f.x, f.y, func(): return {"x": p.x, "y": p.y - 60}, null, 0.2)
	for m in mods:
		if m.has("bin") and active(m) and st.type != null and st.n > 0 and in_r(p, m.bin, 22):
			st.n -= 1
			var f := stack_pos(p, st.n)
			var c := ctr(m.bin)
			fly(st.type, f.x, f.y, func(): return c, null, 0.2)
			if st.n <= 0:
				st.n = 0; st.type = null
			break
	for b in belts:
		if st.type == b.item and in_r(p, b.start) and belt_room(b):
			st.n -= 1
			var f := stack_pos(p, st.n)
			belt_push(b, f.x, f.y)
			if st.n <= 0:
				st.n = 0; st.type = null
	for pd in visible_pads():
		if not in_r(p, pd):
			continue
		var w := wallet()
		if w <= 0:
			continue
		var amt := mini(w, mini(pd.cost - pd.paid, maxi(1, int(ceil(pd.cost / 28.0)))))
		S.money -= amt
		pd.paid += amt
		var px: float = p.x; var py: float = p.y
		fly("coin", px, py - 60, func(): return {"x": pd.x + pd.w / 2, "y": pd.y + pd.h / 2 + 6}, null, 0.22)
		if pd.paid >= pd.cost:
			apply_pad(pd, false)
			compute_reveal()
			save(true)
			burst(ctr(pd))
			events.append({"kind": "unlock", "name": pd.name})
			if pd.fx != "gate":
				toast("Unlocked: " + pd.name + "!", 2.4)
			if pd.fx == "unlock":
				var t = mod_by(pd.t)
				cam_focus = {"x": t.ox + CW / 2, "y": t.oy + CHh / 2, "t": 1.3}
			shake_amt = 5.0

# ===== simulation (L638-718) =====
func new_cust(x: float, y: float, m) -> Dictionary:
	return {"x": x, "y": y, "want": m.want[0] + rng.randi() % (m.want[1] - m.want[0] + 1), "got": 0, "wait": 0.0, "serve": 0.0,
		"at": false, "happy": 0.0, "speed": 110.0, "face": 1, "walk": 0.0, "moving": false,
		"shirt": pick(MooData.SHIRTS), "pants": pick(MooData.PANTS), "skin": pick(MooData.SKINS), "hair": pick(MooData.HAIRS),
		"hat": rng.randf() < 0.4, "item": m.item, "patience": PATIENCE, "say": null, "leave": null}

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
		m.q.append(new_cust(m.ox - 30, m.oy + 330, m))
		m.spawn = rnd(2.4, 4.2) * spawn_factor(m)
	for i in m.q.size():
		var c = m.q[i]
		var s := q_slot(m, i)
		c.at = move_to(c, s.x, s.y, c.speed, dt)
		c.wait += dt
		if c.at:
			c.face = 1
	# customers who waited too long storm off (zombies come with the night port)
	for i in range(m.q.size() - 1, -1, -1):
		var c = m.q[i]
		if c.wait >= c.patience:
			m.q.remove_at(i)
			customer_lost(c, m)
	if m.q.is_empty():
		return
	var c = m.q[0]
	if c.at:
		c.serve -= dt
		if c.serve <= 0 and c.got < c.want and avail(m.box) > 0:
			c.serve = 0.16
			m.box.n -= 1
			c.got += 1
			c.wait = maxf(0.0, c.wait - 3)
			var f := pile_pos(m.box.rect, m.box.n, m.item)
			fly(m.item, f.x, f.y, func(): return {"x": c.x, "y": c.y - 30}, null, 0.2)
		if c.got >= c.want and c.serve <= 0:
			var late: bool = c.wait > c.patience * 0.7
			var amount := int(round(c.want * m.price * (1.5 if late else 1.0)))
			payInto(m, amount, c.x, c.y - 30)
			floaters.append({"x": c.x, "y": c.y - 84, "text": "+" + fmt(amount), "t": 0.0})
			on_served(m, c, amount)
			c.leave = {"x": m.ox + CW + 40, "y": c.y}
			c.happy = 1.6
			if c.say == null and rng.randf() < 0.45:
				say(c, pick(MooData.HAPPY_LINES), 2)
			leaving.append(m.q.pop_front())

func customer_lost(c, m) -> void:
	m.rep = maxf(1.0, m.rep - 0.5)
	c.leave = {"x": m.ox - 60, "y": c.y}
	c.happy = 0.0
	say(c, pick(MooData.LOST_LINES), 1.8)
	leaving.append(c)
	m.lost = m.get("lost", 0) + 1

func on_served(m, c, amount: int) -> void:
	m.sold += amount
	var quick: bool = c.wait < c.patience * 0.4
	m.rep = clampf(m.rep + (0.08 if quick else -0.04), 1, 5)

## payInto (L666): money goes into the shop's pocket; a full pocket spills coins.
func payInto(m, amount: int, fx: float, fy: float) -> void:
	var cash = m.cash
	var cap := pocket_cap(m)
	var fits := int(maxf(0, minf(amount, cap - cash.val)))
	var spill := amount - fits
	if fits > 0:
		cash.val += fits
		var tokens := mini(int(ceil(fits / maxf(1, m.price))), 12)
		for k in tokens:
			cash.n += 1
			var idx: int = cash.n - 1
			fly(cash.type, fx, fy, func(): return pile_pos(cash.rect, idx, cash.type), cash, 0.25 + k * 0.03)
	if spill > 0:
		var n := mini(6, maxi(1, int(ceil(spill / maxf(1, m.price)))))
		var r = cash.rect
		for i in n:
			ground.append({"x": r.x + r.w / 2 + rnd(-70, 70), "y": r.y + r.h + rnd(10, 50), "val": spill / n + (1 if i < spill % n else 0),
				"t": 30.0, "fx": r.x + r.w / 2, "fy": r.y, "ft": 0.0})
		if not m.has("spillWarn") or T - m.spillWarn > 8:
			m.spillWarn = T
			toast("💸 " + m.name + " is overflowing — coins are spilling!", 2.4)

func upd_machine(m, dt: float) -> void:
	var sp := 18.0 if m.kind == "cow" else (30.0 if m.kind == "hen" else 0.0)
	for u in m.units:
		if u.anim > 0:
			u.anim -= dt
		if sp > 0:
			if u.eat > 0:
				u.eat -= dt
			elif move_to(u, u.tx, u.ty, sp, dt):
				u.idle -= dt
				if u.idle <= 0:
					u.tx = rnd(m.area.x + 20, m.area.x + m.area.w - 20)
					u.ty = rnd(m.area.y + 30, m.area.y + m.area.h)
					u.idle = rnd(1, 3)
		u.timer += dt
		if u.timer >= m.period:
			if avail(m.hopper) > 0 and m.tray.n < m.tray.cap:
				u.timer = 0.0
				m.hopper.n -= 1
				u.eat = 0.8 if sp > 0 else 0.0
				u.anim = 0.5
				var idx: int = m.tray.n
				m.tray.n += 1
				var tr = m.tray
				fly(m.out, u.x, u.y - 24, func(): return pile_pos(tr.rect, idx, m.out), tr, 0.45)
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
					var d := dist(t, h)
					if d < bd:
						bd = d; best = t
			if not in_r(h, F, 6):
				walk_to(h, F.x + F.w / 2, F.y + F.h / 2, 150, dt)
				return
			if best == null:
				if st.n > 0:
					h.state = "to"
				return
			if move_to(h, best.x, best.y + 8, 150, dt) and h.t <= 0:
				h.t = 0.12
				harvest(best, h, h.field.item)
		elif walk_to(h, h.fromStand.x, h.fromStand.y, 150, dt) and h.t <= 0:
			if avail(h.from) > 0 and h.stack.n < h.cap:
				h.t = 0.1
				take(h.from, h)
			elif h.stack.n > 0:
				h.state = "to"
	else:
		if walk_to(h, h.toStand.x, h.toStand.y, 150, dt) and h.t <= 0:
			if h.stack.n > 0:
				if h.belt != null:
					if belt_room(h.belt):
						h.t = 0.12
						give_belt(h, h.belt)
				elif h.to.n < h.to.cap:
					h.t = 0.1
					give(h, h.to)
			else:
				h.state = "from"

# ===== guide arrow (L755-793) =====
var g_mode = null

func nearest_ripe(item: String, list: Array):
	var b = null
	var bd := 1e9
	for m in list:
		if m.type == "field" and m.item == item:
			for t in m.tiles:
				if t.t <= 0:
					var d := dist(t, player)
					if d < bd:
						bd = d; b = t
	return b

func tray_source(item: String, list: Array, mn: int = 1):
	for m in list:
		if m.has("tray") and m.tray.type == item and avail(m.tray) >= mn:
			return ctr(m.tray.rect)
	return null

func any_source(item: String, list: Array):
	var s = tray_source(item, list)
	if s != null:
		return s
	var t = nearest_ripe(item, list)
	return {"x": t.x, "y": t.y} if t != null else null

## destsFor (L762): where an item can go right now (needRoom = there is space).
func dests_for(item: String, list: Array, need_room: bool) -> Array:
	var r := []
	for m in list:
		if m.type == "machine" and m["in"] == item and (not need_room or m.hopper.n < m.hopper.cap):
			r.append(ctr(m.inPad))
		if m.type == "counter" and m.item == item and (not need_room or m.box.n < m.box.cap):
			r.append(ctr(m.drop))
	return r

func nearest(list: Array):
	var b = null
	for x in list:
		if b == null or dist(x, player) < dist(b, player):
			b = x
	return b

func guide_target():
	var st = player.stack
	var aff := visible_pads().any(func(p): return wallet() >= p.cost - p.paid)
	var sig := str(st.type) + str(st.n >= S.cap) + str(S.ch) + "|" + str(aff)
	if g_cache != null and T < g_cache.until and g_cache.sig == sig and g_cache.p != null and dist(player, g_cache.p) > 25:
		return g_cache.p
	var r = guide_raw()
	g_cache = {"p": r, "until": T + 2.5, "sig": sig}
	return r

func guide_raw():
	var st = player.stack
	var L := live()
	for p in visible_pads():
		if wallet() >= p.cost - p.paid:
			return ctr(p)
	if st.type == null:
		g_mode = null
	elif st.n >= S.cap:
		g_mode = "deliver"
	if st.type != null and g_mode != "deliver":
		var s = any_source(st.type, L)
		if s != null and dests_for(st.type, L, true).size():
			return s
		g_mode = "deliver"
	if st.type != null:
		var d = nearest(dests_for(st.type, L, true))
		if d != null:
			return d
		for m in L:
			if m.type == "counter" and avail(m.cash) > 0:
				return ctr(m.cash.rect)
		var bins := []
		for m in L:
			if m.has("bin"):
				bins.append(ctr(m.bin))
		var switch_task := L.any(func(m): return m.type == "counter" and m.item != st.type and m.box.n < m.box.cap - 3 and tray_source(m.item, L, 4) != null)
		var wait = nearest(dests_for(st.type, L, false))
		if wait != null and not switch_task:
			return wait
		var nb = nearest(bins)
		return nb if nb != null else wait
	for m in L:
		if m.type == "counter" and avail(m.cash) > 0:
			return ctr(m.cash.rect)
	var cs := L.filter(func(m): return m.type == "counter")
	cs.sort_custom(func(a, b): return a.box.n < b.box.n)
	for m in cs:
		if m.box.n < m.box.cap - 3:
			var s = tray_source(m.item, L, 2)
			if s != null:
				return s
	var ms := L.filter(func(m): return m.type == "machine" and not belts.any(func(b): return b.m == m))
	ms.sort_custom(func(a, b): return a.hopper.n < b.hopper.n)
	for m in ms:
		if m.hopper.n < m.hopper.cap - 4:
			var s = any_source(m["in"], L)
			if s != null:
				return s
	for m in L:
		if m.type == "machine" and m.hopper.n < m.hopper.cap - 4:
			var t = nearest_ripe(m["in"], L)
			if t != null:
				return {"x": t.x, "y": t.y}
	for m in cs:
		if m.box.n < m.box.cap:
			var s = tray_source(m.item, L, 1)
			if s != null:
				return s
	return null

# ===== update (L795-850) =====
func update(dt: float) -> void:
	T += dt
	warn_t -= dt
	var p = player
	var dir := Vector2.ZERO
	var mag := 0.0
	if move_in.length() > 0.001:
		dir = move_in.normalized()
		mag = minf(1.0, move_in.length())
	if test_in.length() > 0.001:
		dir = test_in.normalized()
		mag = 1.0
	p.moving = mag > 0
	var px0: float = p.x
	var py0: float = p.y
	var sp := SPEED
	p.vx = dir.x * mag * sp if mag > 0 else 0.0
	if mag > 0:
		p.x += dir.x * mag * sp * dt
		p.y += dir.y * mag * sp * dt
		p.walk += dt * 12 * mag
		if absf(dir.x) > 0.1:
			p.face = 1 if dir.x > 0 else -1
	if not no_clip:
		# 1) stay inside the open world (hard-won fix: one solid boundary)
		if not walkable(p.x, p.y):
			if walkable(p.x, py0):
				p.y = py0
			elif walkable(px0, p.y):
				p.x = px0
			else:
				p.x = px0; p.y = py0
		# 2) then get pushed out of anything solid
		collide_player(p)
		if not walkable(p.x, p.y):
			p.x = px0; p.y = py0
	if bounds == null:
		bounds = target_bounds.duplicate()
	var bk := minf(1.0, dt * 2.5)
	for k in ["x0", "y0", "x1", "y1"]:
		bounds[k] += (target_bounds[k] - bounds[k]) * bk
	p.x = clampf(p.x, bounds.x0 + 14, bounds.x1 - 14)
	p.y = clampf(p.y, bounds.y0 + 30, bounds.y1 - 10)
	# safety net: never let the player stay wedged inside something solid
	if not no_clip and blocked_at(p.x, p.y, 8):
		p.pinned += dt
		if p.pinned > 0.6:
			var f := nearest_free(nav_gx(p.x), nav_gy(p.y))
			p.x = nav_cx(f.x); p.y = nav_cy(f.y)
			p.pinned = 0.0
	else:
		p.pinned = 0.0
	for c in cells:
		var tgt := 0.0 if c.on else 1.0
		c.fog += (tgt - c.fog) * minf(1.0, dt * 2)
	for m in mods:
		if not active(m):
			continue
		if m.type == "field":
			for t in m.tiles:
				if t.t > 0:
					t.t -= dt
		elif m.type == "machine":
			upd_machine(m, dt)
		elif m.type == "counter":
			upd_counter(m, dt)
	for b in belts:
		upd_belt(b, dt)
	act_t += dt
	while act_t >= ACT_TICK:
		act_t -= ACT_TICK
		act()
	for i in range(leaving.size() - 1, -1, -1):
		var c = leaving[i]
		c.happy -= dt
		if move_to(c, c.leave.x, c.leave.y, c.speed, dt):
			leaving.remove_at(i)
	for h in helpers:
		upd_helper(h, dt)
	upd_ground(dt)
	upd_speech(dt)
	for i in range(flyers.size() - 1, -1, -1):
		var f = flyers[i]
		f.t += dt
		if f.t >= f.dur:
			if f.dest != null:
				f.dest.inc -= 1
			flyers.remove_at(i)
	for i in range(floaters.size() - 1, -1, -1):
		floaters[i].t += dt
		if floaters[i].t > 1.2:
			floaters.remove_at(i)
	for i in range(toasts.size() - 1, -1, -1):
		toasts[i].t += dt
		if toasts[i].t > toasts[i].dur:
			toasts.remove_at(i)
	for i in range(sparks.size() - 1, -1, -1):
		var s = sparks[i]
		s.t += dt
		s.vy += 420 * dt
		s.x += s.vx * dt
		s.y += s.vy * dt
		if s.t > 0.9:
			sparks.remove_at(i)
	if cam_focus != null:
		cam_focus.t -= dt
		if cam_focus.t <= 0:
			cam_focus = null
	shake_amt = maxf(0.0, shake_amt - dt * 20)
	saved_flash = maxf(0.0, saved_flash - dt)
	save_t += dt
	if save_t > SAVE_EVERY:
		save_t = 0.0
		save(false)

func upd_ground(dt: float) -> void:
	for i in range(ground.size() - 1, -1, -1):
		var c = ground[i]
		c.ft += dt
		c.t -= dt
		if c.ft > 0.35 and dist(c, player) < 34:
			S.money += c.val
			events.append({"kind": "coin"})
			ground.remove_at(i)
			continue
		if c.t <= 0:
			ground.remove_at(i)

func upd_speech(dt: float) -> void:
	var ents: Array = [player]
	for m in mods:
		if m.type == "counter":
			ents.append_array(m.q)
	ents.append_array(leaving)
	for e in ents:
		if e.get("say") != null:
			e.say.t -= dt
			if e.say.t <= 0:
				e.say = null

# ===== solid world (L852-950) =====
func cell_obstacles(c) -> Array:
	var o := []
	if not c.on:
		o.append({"r": {"x": c.x, "y": c.y, "w": c.w, "h": c.h}, "fog": true})
		return o
	var m = c.mod
	if m != null:
		if m.type == "garage":
			o.append({"r": m.shop})
		if not active(m):
			return o
		if m.type == "machine":
			o.append({"r": m.pen})
		if m.type == "counter":
			o.append({"r": m.bench})
		if m.has("bin"):
			o.append({"r": m.bin})
	return o

func refresh_obstacles() -> void:
	for c in cells:
		c.obs = cell_obstacles(c)
	build_nav()
	for h in helpers:
		h.path = null

func near_obs(x: float, y: float, R: float) -> Array:
	var out := []
	for c in cells:
		if x < c.x - R or x > c.x + c.w + R or y < c.y - R or y > c.y + c.h + R:
			continue
		out.append_array(c.obs)
	return out

func push_out(e, o, R: float) -> void:
	var r = o.r
	var cx := clampf(e.x, r.x, r.x + r.w)
	var cy := clampf(e.y, r.y, r.y + r.h)
	var dx: float = e.x - cx
	var dy: float = e.y - cy
	var d := sqrt(dx * dx + dy * dy)
	if d >= R:
		return
	if d == 0:
		var l: float = e.x - r.x
		var rt: float = r.x + r.w - e.x
		var t: float = e.y - r.y
		var b: float = r.y + r.h - e.y
		var mm := minf(minf(l, rt), minf(t, b))
		if mm == l: e.x = r.x - R
		elif mm == rt: e.x = r.x + r.w + R
		elif mm == t: e.y = r.y - R
		else: e.y = r.y + r.h + R
	else:
		e.x = cx + dx / d * R
		e.y = cy + dy / d * R

func blocked_at(x: float, y: float, R: float = 12.0) -> bool:
	for o in near_obs(x, y, 60):
		var r = o.r
		var cx := clampf(x, r.x, r.x + r.w)
		var cy := clampf(y, r.y, r.y + r.h)
		if Vector2(x - cx, y - cy).length() < R:
			return true
	return false

## clouds: push out toward an edge that stays inside the open world (L895)
func push_out_fog(e, r) -> void:
	var R := 12.0
	var cx := clampf(e.x, r.x, r.x + r.w)
	var cy := clampf(e.y, r.y, r.y + r.h)
	var dx: float = e.x - cx
	var dy: float = e.y - cy
	var d := sqrt(dx * dx + dy * dy)
	if d >= R:
		return
	if d > 0:
		e.x = cx + dx / d * R
		e.y = cy + dy / d * R
		if in_bounds(e):
			return
	var B = bounds if bounds != null else target_bounds
	var opts := [{"x": r.x - R, "y": e.y}, {"x": r.x + r.w + R, "y": e.y}, {"x": e.x, "y": r.y - R}, {"x": e.x, "y": r.y + r.h + R}].filter(
		func(o): return o.x >= B.x0 + 14 and o.x <= B.x1 - 14 and o.y >= B.y0 + 30 and o.y <= B.y1 - 10)
	if opts.is_empty():
		return
	var best = opts[0]
	for o in opts:
		if dist(o, e) < dist(best, e):
			best = o
	e.x = best.x
	e.y = best.y

func in_bounds(e) -> bool:
	var B = bounds if bounds != null else target_bounds
	return e.x >= B.x0 + 14 and e.x <= B.x1 - 14 and e.y >= B.y0 + 30 and e.y <= B.y1 - 10

func collide_player(p) -> void:
	var obs := near_obs(p.x, p.y, 80)
	for k in 3:
		for o in obs:
			if o.get("fog", false):
				push_out_fog(p, o.r)
			else:
				push_out(p, o, 12)

## the open world = revealed cells; you can never walk into the clouds (L940)
func walkable(x: float, y: float) -> bool:
	var near := false
	for c in cells:
		if x < c.x - 50 or x > c.x + c.w + 50 or y < c.y - 50 or y > c.y + c.h + 50:
			continue
		var inside: bool = x >= c.x and x < c.x + c.w and y >= c.y and y < c.y + c.h
		if not c.on and inside:
			return false
		if c.on:
			near = true
	return near

# navigation grid + A* (L911-937)
func nav_gx(x: float) -> int: return int(floor((x - NAV.ox) / NAV.s))
func nav_gy(y: float) -> int: return int(floor((y - NAV.oy) / NAV.s))
func nav_cx(gx: int) -> float: return NAV.ox + gx * NAV.s + NAV.s / 2.0
func nav_cy(gy: int) -> float: return NAV.oy + gy * NAV.s + NAV.s / 2.0

func build_nav() -> void:
	var blk := PackedByteArray()
	blk.resize(NAV.nx * NAV.ny)
	for gy in NAV.ny:
		for gx in NAV.nx:
			if blocked_at(nav_cx(gx), nav_cy(gy), 14):
				blk[gy * NAV.nx + gx] = 1
	NAV.blk = blk

func nav_free(gx: int, gy: int) -> bool:
	return gx >= 0 and gy >= 0 and gx < NAV.nx and gy < NAV.ny and NAV.blk[gy * NAV.nx + gx] == 0

func nearest_free(gx: int, gy: int) -> Vector2i:
	if nav_free(gx, gy):
		return Vector2i(gx, gy)
	for r in range(1, 25):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) == r and nav_free(gx + dx, gy + dy):
					return Vector2i(gx + dx, gy + dy)
	return Vector2i(gx, gy)

func line_free(ax: float, ay: float, bx: float, by: float) -> bool:
	var d := Vector2(bx - ax, by - ay).length()
	var n := int(ceil(d / 8))
	for i in range(1, n):
		var x := ax + (bx - ax) * i / n
		var y := ay + (by - ay) * i / n
		if not nav_free(nav_gx(x), nav_gy(y)):
			return false
	return true

func find_path(ax: float, ay: float, bx: float, by: float):
	var nx: int = NAV.nx
	if line_free(ax, ay, bx, by):
		return [{"x": bx, "y": by}]
	var s0 := nearest_free(nav_gx(ax), nav_gy(ay))
	var t0 := nearest_free(nav_gx(bx), nav_gy(by))
	var N: int = nx * NAV.ny
	var g := PackedFloat32Array(); g.resize(N); g.fill(1e9)
	var from := PackedInt32Array(); from.resize(N); from.fill(-1)
	var closed := PackedByteArray(); closed.resize(N)
	var heap: Array = []
	var hfn := func(x: int, y: int) -> float:
		var dx := absi(x - t0.x); var dy := absi(y - t0.y)
		return dx + dy - 0.59 * mini(dx, dy)
	var si := s0.y * nx + s0.x
	var ti := t0.y * nx + t0.x
	g[si] = 0
	_hpush(heap, si, hfn.call(s0.x, s0.y))
	var it := 0
	while heap.size() and it < 60000:
		it += 1
		var i: int = _hpop(heap)[1]
		if closed[i]:
			continue
		closed[i] = 1
		if i == ti:
			break
		var x := i % nx
		var y := i / nx
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var X: int = x + dx
				var Y: int = y + dy
				if not nav_free(X, Y):
					continue
				if dx != 0 and dy != 0 and (not nav_free(x + dx, y) or not nav_free(x, y + dy)):
					continue
				var j := Y * nx + X
				var ng := g[i] + (1.41 if dx != 0 and dy != 0 else 1.0)
				if ng < g[j]:
					g[j] = ng
					from[j] = i
					_hpush(heap, j, ng + hfn.call(X, Y))
	if from[ti] < 0 and ti != si:
		return null
	var pts := []
	var k := ti
	while k != si and k >= 0:
		pts.append({"x": nav_cx(k % nx), "y": nav_cy(k / nx)})
		k = from[k]
	pts.reverse()
	pts.append({"x": bx, "y": by})
	# smooth: skip waypoints we can see past
	var out := []
	var cx := ax; var cy := ay; var q := 0
	while q < pts.size():
		var j := pts.size() - 1
		while j > q and not line_free(cx, cy, pts[j].x, pts[j].y):
			j -= 1
		out.append(pts[j])
		cx = pts[j].x; cy = pts[j].y
		q = j + 1
	return out

static func _hpush(heap: Array, i: int, f: float) -> void:
	heap.append([f, i])
	var k := heap.size() - 1
	while k > 0:
		var p := (k - 1) >> 1
		if heap[p][0] <= heap[k][0]:
			break
		var tmp = heap[p]; heap[p] = heap[k]; heap[k] = tmp
		k = p

static func _hpop(heap: Array) -> Array:
	var top = heap[0]
	var last = heap.pop_back()
	if heap.size():
		heap[0] = last
		var k := 0
		while true:
			var l := 2 * k + 1
			var r := l + 1
			var m := k
			if l < heap.size() and heap[l][0] < heap[m][0]: m = l
			if r < heap.size() and heap[r][0] < heap[m][0]: m = r
			if m == k:
				break
			var tmp = heap[m]; heap[m] = heap[k]; heap[k] = tmp
			k = m
	return top

func walk_to(h, tx: float, ty: float, sp: float, dt: float) -> bool:
	var key := str(round(tx)) + "," + str(round(ty))
	if h.pathKey != key or h.path == null:
		var pth = find_path(h.x, h.y, tx, ty)
		h.path = pth if pth != null else [{"x": tx, "y": ty}]
		h.pathKey = key
	while h.path.size() > 1 and Vector2(h.path[0].x - h.x, h.path[0].y - h.y).length() < 4:
		h.path.pop_front()
	var wp = h.path[0]
	var arrived := move_to(h, wp.x, wp.y, sp, dt)
	return h.path.size() == 1 and arrived

# ===== saves (L2008-2050, L2064-2090) =====
func snapshot() -> Dictionary:
	var bx := {}
	for m in mods:
		var o := {}
		if m.has("hopper"): o.h = avail(m.hopper)
		if m.has("tray"): o.t = avail(m.tray)
		if m.has("box"): o.b = avail(m.box)
		if m.has("cash"):
			o.cn = avail(m.cash); o.cv = m.cash.val
		if o.size():
			bx[m.key] = o
	var bl := {}
	for b in belts:
		bl[b.m.key] = b.items.size()
	var pk := {}
	for p in pads:
		if p.paid > 0:
			pk[str(p.d) + ":" + p.name] = p.paid
	var rep := {}
	for m in mods:
		if m.has("rep"):
			rep[m.key] = round(m.rep * 10) / 10.0
	var st = player.stack
	return {"v": 1, "ver": 9, "engine": "godot", "t": int(Time.get_unix_time_from_system() * 1000), "ch": S.ch, "money": S.money,
		"votes": 0, "cap": S.cap, "won": false, "done": S.done,
		"paid": pads.map(func(p): return p.paid), "pk": pk, "bx": bx, "bl": bl,
		"px": int(round(player.x)), "py": int(round(player.y)), "rep": rep,
		"hold": [st.type, maxi(0, st.n - st.inc)] if st.type != null else null}

func fresh_state() -> void:
	build_world()
	S = {"ch": 0, "money": 0, "votes": 0, "cap": 8, "won": false, "done": false}
	T = 0.0; act_t = 0.0; save_t = 0.0; warn_t = 0.0; g_cache = null; g_mode = null
	toasts = []; events = []; cam_focus = null
	compute_reveal()
	bounds = target_bounds.duplicate()
	for c in cells:
		c.fog = 0.0 if c.on else 1.0

func apply_state(d: Dictionary) -> void:
	fresh_state()
	S.ch = 0
	S.money = int(d.get("money", 0))
	S.cap = maxi(int(d.get("cap", 8)), 8)
	S.done = bool(d.get("done", false))
	var paid = d.get("paid")
	if int(d.get("ver", 0)) >= 9 and paid is Array and paid.size() == pads.size():
		for i in pads.size():
			pads[i].paid = mini(int(paid[i]), pads[i].cost)
	elif d.get("pk") is Dictionary:
		# keyed by name: a reordered pad list keeps finished upgrades finished
		for p in pads:
			var v = d.pk.get(str(p.d) + ":" + p.name)
			if v != null:
				p.paid = p.cost if int(v) >= p.cost * 0.9 else mini(p.cost - 1, int(v))
	for p in pads:
		if p.paid >= p.cost:
			apply_pad(p, true)
	var bx = d.get("bx", {})
	for m in mods:
		var o = bx.get(m.key)
		if o == null:
			continue
		if m.has("hopper") and o.has("h"): m.hopper.n = clampi(int(o.h), 0, m.hopper.cap)
		if m.has("tray") and o.has("t"): m.tray.n = clampi(int(o.t), 0, m.tray.cap)
		if m.has("box") and o.has("b"): m.box.n = clampi(int(o.b), 0, m.box.cap)
		if m.has("cash") and o.has("cn"):
			m.cash.n = maxi(0, int(o.cn)); m.cash.val = maxi(0, int(o.cv))
	var bl = d.get("bl", {})
	for b in belts:
		var n := int(bl.get(b.m.key, 0))
		for i in n:
			b.items.append(maxf(0.0, b.len - i * b.gap))
	if d.get("px") != null:
		player.x = float(d.px); player.y = float(d.py)
	var hold = d.get("hold")
	if hold is Array and MooData.ITEMS.has(str(hold[0])):
		player.stack = {"type": str(hold[0]), "n": mini(int(hold[1]), S.cap), "inc": 0}
		if player.stack.n <= 0:
			player.stack.type = null
	var rep = d.get("rep", {})
	for m in mods:
		if rep.has(m.key):
			m.rep = float(rep[m.key])
	compute_reveal()
	bounds = target_bounds.duplicate()
	for c in cells:
		c.fog = 0.0 if c.on else 1.0
	if blocked_at(player.x, player.y, 6):
		var f := nearest_free(nav_gx(player.x), nav_gy(player.y))
		player.x = nav_cx(f.x); player.y = nav_cy(f.y)

func slot_path(i: int) -> String:
	return save_dir.path_join("moo-rush-slot-%d.json" % i)

func read_slot(i: int):
	if not FileAccess.file_exists(slot_path(i)):
		return null
	var txt := FileAccess.get_file_as_string(slot_path(i))
	var d = JSON.parse_string(txt)
	return d if d is Dictionary else null

func write_slot(i: int, d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var f := FileAccess.open(slot_path(i), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()

func delete_slot(i: int) -> void:
	if FileAccess.file_exists(slot_path(i)):
		DirAccess.remove_absolute(slot_path(i))
	if i == cur_slot:
		cur_slot = 0
		fresh_state()

func save(important: bool) -> void:
	if cur_slot == 0 or not autosave:
		return
	write_slot(cur_slot, snapshot())
	if important:
		saved_flash = 1.4

## startSlot (L2096): load the slot, or start fresh in it.
func start_slot(i: int) -> bool:
	cur_slot = i
	var d = read_slot(i)
	if d != null:
		apply_state(d)
		toast("Slot %d loaded — welcome back!" % i, 2.2)
		return true
	fresh_state()
	save(true)
	return false

# ===== test API helpers =====
func pad_named(name: String):
	for p in pads:
		if p.name == name:
			return p
	return null

func state_summary() -> Dictionary:
	var out := {"t": T, "money": S.money, "cap": S.cap, "done": S.done, "x": player.x, "y": player.y,
		"stack": [player.stack.type, player.stack.n], "pads": {}, "helpers": helpers.size()}
	for p in pads:
		out.pads[p.name] = [p.paid, p.cost]
	return out

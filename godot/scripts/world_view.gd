extends Node2D
## Draws the world with _draw() (prototype draw(), L1540-1750) and runs the
## camera (camTarget/moveCam, L834-842). The node transform is the camera.

const ZombiePaint = preload("res://scripts/zombie_paint.gd")
const THEME0 := "#86c25a"
var sim: MooSim
var cam := Vector2.ZERO
var zoom := 1.0
var vis_rect := Rect2()
var tufts: Array = []
var grass_lines := PackedVector2Array()
var cam_snapped := false
var draw_cpu_us := 0
var night_view = preload("res://scripts/night_view.gd").new()
var cull_people := true  # false only for the A/B look test

func _ready() -> void:
	sim = Moo.sim
	var s := 7
	for i in 120:
		s = (s * 16807) % 2147483647
		var a := s / 2147483647.0
		s = (s * 16807) % 2147483647
		tufts.append(Vector2(a * 600, s / 2147483647.0 * 600))
	for t in tufts:
		grass_lines.append_array(PackedVector2Array([Vector2(t.x - 3, t.y - 4), t, t, Vector2(t.x + 3, t.y - 5)]))
	add_child(night_view)
	Paint.prime_items(self)
	Moo.slot_started.connect(func(_i): cam_snapped = false)

func view_size() -> Vector2:
	return get_viewport_rect().size

func cam_target() -> Vector2:
	var vs := view_size()
	var vw := vs.x / zoom
	var vh := vs.y / zoom
	var b = sim.bounds if sim.bounds != null else sim.target_bounds
	var bw: float = b.x1 - b.x0
	var bh: float = b.y1 - b.y0
	var fx: float = sim.cam_focus.x if sim.cam_focus != null else sim.player.x
	var fy: float = sim.cam_focus.y if sim.cam_focus != null else sim.player.y
	var tx: float = b.x0 + (bw - vw) / 2 if vw >= bw else clampf(fx - vw / 2, b.x0, b.x1 - vw)
	var ty: float = b.y0 + (bh - vh) / 2 if vh >= bh else clampf(fy - vh * 0.55, b.y0, b.y1 - vh)
	return Vector2(tx, ty)

func _process(delta: float) -> void:
	sim = Moo.sim
	var vs := view_size()
	zoom = minf(vs.x / 560.0, vs.y / (560.0 * 1.36))  # resize() L2219, zoom 'normal'
	if not Moo.paused and not Moo.suspended:
		sim.update(minf(delta, 0.05))
	if not Moo.paused and not Moo.suspended:
		Moo.audio.consume(sim.events)
	sim.events.clear()
	var t := cam_target()
	if not cam_snapped:
		cam = t
		cam_snapped = true
	else:
		cam += (t - cam) * minf(1.0, delta * 6)
	var sh := Vector2.ZERO
	if sim.shake_amt > 0:
		sh = Vector2(randf_range(-sim.shake_amt, sim.shake_amt), randf_range(-sim.shake_amt, sim.shake_amt))
	transform = Transform2D(0.0, Vector2(zoom, zoom), 0.0, -(cam + sh) * zoom)
	vis_rect = Rect2(cam.x - 60, cam.y - 60, vs.x / zoom + 120, vs.y / zoom + 120)
	night_view.refresh(sim, vis_rect)
	queue_redraw()

func vis(r) -> bool:
	return vis_rect.intersects(Rect2(r.x, r.y, r.w, r.h))

func C(h: String, a: float = 1.0) -> Color:
	return Paint.C(h, a)

# ===== world pieces =====
func drop_pad(r, ic: String) -> void:
	var on := MooSim.in_r(sim.player, r)
	Paint.fill_rr(self, r.x, r.y, r.w, r.h, 12, Color(1, 1, 1, 0.35 if on else 0.14))
	Paint.dash_rr(self, r.x, r.y, r.w, r.h, Color(1, 1, 1, 0.9), 3, 9)
	Paint.item(self, ic, r.x + r.w / 2, r.y + r.h / 2 + 14, 1.3, 0.55)

## Light shallow wooden crate; item and pickup rectangles keep their dimensions.
static func tray_base(ci: CanvasItem, r) -> void:
	Paint.fill_rr(ci, r.x - 5, r.y - 2, r.w + 14, r.h + 14, 12, Color(0, 0, 0, 0.15))
	Paint.fill_rr(ci, r.x - 7, r.y - 7, r.w + 14, r.h + 14, 12, Paint.C("#bf935e"))
	Paint.fill_rr(ci, r.x, r.y, r.w, r.h, 7, Paint.C("#ecd1a7"))
	var x: float = r.x + 46
	while x < r.x + r.w - 5:
		ci.draw_line(Vector2(x, r.y + 2), Vector2(x, r.y + r.h - 2), Paint.C("#d5b384"), 1.2)
		x += 46
	Paint.fill_rr(ci, r.x - 4, r.y - 5, r.w + 8, 4, 2, Paint.C("#ffe1af"))
	Paint.fill_rr(ci, r.x - 4, r.y + r.h, r.w + 8, 4, 2, Paint.C("#d2a36a"))
	Paint.stroke_rr(ci, r.x - 7, r.y - 7, r.w + 14, r.h + 14, 12, Paint.C("#9d7548"), 1.5)
	for dx in [0.0, float(r.w)]:
		for dy in [0.0, float(r.h)]:
			Paint.circ(ci, r.x + dx, r.y + dy, 1.3, Paint.C("#9d7548"))

func tray(b) -> void:
	tray_base(self, b.rect)
	draw_pile(b)

func draw_pile(b, max_draw: int = 200) -> void:
	var v := mini(max_draw, maxi(0, MooSim.avail(b)))
	var slots: Array = sim.visible_slots(b) if b.has("item_slots") else range(v)
	slots.sort()
	for i in slots.slice(0, v):
		var p := sim.pile_pos(b.rect, i, b.type)
		Paint.item(self, b.type, p.x, p.y)

func label(t: String, x: float, y: float, size: float = 15) -> void:
	Paint.text(self, t, x, y, size, Color.WHITE, Color(40 / 255.0, 25 / 255.0, 10 / 255.0, 0.55))

func fence(r, col: String, top: String) -> void:
	draw_rect(Rect2(r.x, r.y, r.w, r.h), C(col), false, 8)
	draw_rect(Rect2(r.x, r.y - 2, r.w, r.h), C(top), false, 3)
	var nx := maxi(1, int(round(r.w / 40)))
	var ny := maxi(1, int(round(r.h / 40)))
	var post := func(x: float, y: float):
		Paint.fill_rr(self, x - 5, y - 9, 10, 13, 2, C(col))
		Paint.fill_rr(self, x - 5, y - 11, 10, 6, 2, C(top))
	for i in nx + 1:
		var x: float = r.x + r.w * i / nx
		post.call(x, r.y); post.call(x, r.y + r.h)
	for i in range(1, ny):
		var y: float = r.y + r.h * i / ny
		post.call(r.x, y); post.call(r.x + r.w, y)

func draw_module(m) -> void:
	if m.type in ["garage", "armory", "bank"]:
		draw_shop_building(m)
		return
	if m.locked:
		var B = m.cell
		Paint.fill_rr(self, B.x + 14, B.y + 14, B.w - 28, B.h - 28, 18, Color(60 / 255.0, 90 / 255.0, 30 / 255.0, 0.16))
		Paint.dash_rr(self, B.x + 14, B.y + 14, B.w - 28, B.h - 28, Color(1, 1, 1, 0.55), 3, 12)
		Paint.text(self, m.get("name", ""), B.x + B.w / 2, B.y + 52, 20, Color(1, 1, 1, 0.9))
		return
	var ox: float = m.ox
	var oy: float = m.oy
	match m.type:
		"field":
			var r = m.rect
			Paint.fill_rr(self, r.x, r.y, r.w, r.h, 6, C("#8b5a36"))
			for i in 5:
				var y: float = r.y + 31 + i * 50
				draw_line(Vector2(r.x + 8, y), Vector2(r.x + r.w - 8, y), C("#7a4d2d"), 3)
			for t in m.tiles:
				if t.t <= 0:
					match m.item:
						"corn": draw_corn_plant(t.x, t.y)
						"wheat": draw_wheat_plant(t.x, t.y)
						"apple": draw_apple_tree(t.x, t.y)
						_: Paint.item(self, m.item, t.x, t.y + 8, 1.2)
				else:
					var g: float = 1 - t.t / MooSim.REGROW
					var h := 4 + 12 * g
					var c := C("#5cb84f")
					draw_line(Vector2(t.x, t.y + 6), Vector2(t.x, t.y + 6 - h), c, 2.5)
					draw_line(Vector2(t.x, t.y + 6 - h * 0.5), Vector2(t.x - h * 0.5, t.y + 6 - h), c, 2.5)
					draw_line(Vector2(t.x, t.y + 6 - h * 0.6), Vector2(t.x + h * 0.5, t.y + 6 - h * 1.1), c, 2.5)
			fence(r, "#a8642c", "#d48b47")
			label(m.name, r.x + r.w / 2, r.y - 20)
		"machine":
			var p = m.pen
			draw_rect(Rect2(p.x, p.y, p.w, p.h), C("#e8c77d"))
			if m.kind == "cow":
				fence(p, "#b8432f", "#d9624a")
			else:
				fence(p, "#a8642c", "#d48b47")
			Paint.fill_rr(self, p.x - 4, p.y - 12, p.w + 8, 16, 5, C("#4a90c8" if m.kind == "cow" else "#7a8696"))
			label(m.name, p.x + p.w / 2, p.y - 28)
			var h = m.hopper.rect
			Paint.fill_rr(self, h.x - 4, h.y - 4, h.w + 8, h.h + 8, 6, C("#6b3f22"))
			Paint.fill_rr(self, h.x, h.y, h.w, h.h, 4, C("#4b2a14"))
			draw_pile(m.hopper)
			drop_pad(m.inPad, m["in"])
			tray(m.tray)
		"counter":
			drop_pad(m.drop, m.item)
			var c = m.cash
			var r = c.rect
			Paint.dash_rr(self, r.x - 4, r.y - 4, r.w + 8, r.h + 8, Color(1, 1, 1, 0.6), 2, 7)
			if MooSim.avail(c) <= 0:
				Paint.item(self, c.type, r.x + r.w / 2, r.y + r.h / 2 + 14, 1.4, 0.45)
			else:
				draw_pile(c, 120)
		"gate":
			var c := MooSim.ctr(m.pad)
			Paint.fill_rr(self, ox + 30, oy + 30, MooSim.CW - 60, MooSim.CHh - 60, 26, Color(1, 1, 1, 0.14))
			Paint.text(self, "Next up", c.x, oy + 64, 17, Color(1, 1, 1, 0.85))
			Paint.emoji_at(self, MooData.RANKS[m.d + 1], c.x - 70, oy + 142 - 12 * 1.7, 24 * 1.7)
			Paint.text(self, MooData.TITLES[m.d + 1], c.x + 24, oy + 112, 28, Color.WHITE, Color(40 / 255.0, 25 / 255.0, 10 / 255.0, 0.5))

## Prototype drawDecor: ponds sit below the y-sorted trees and people.
func draw_decor(cell) -> void:
	for decoration in cell.get("decor", []):
		if decoration.kind != "pond":
			continue
		var x: float = decoration.x
		var y: float = decoration.y
		var rx: float = decoration.rx
		var ry: float = decoration.ry
		Paint.ell(self, x, y, rx, ry, C("#3f8fd0"))
		Paint.ell(self, x, y - 3, rx - 8, ry - 8, C("#5aa9e6"))
		Paint.ell(self, x - 20, y - 12, 25, 7, Color(1, 1, 1, 0.35))
		Paint.stroke_ell(self, x, y, rx + 2, ry + 2, C("#c9b48a"), 5)

## Prototype drawTree; the trunk ground position participates in entity sorting.
func draw_tree(tree) -> void:
	var x: float = tree.x
	var y: float = tree.y
	var r: float = tree.r
	Paint.ell(self, x, y + r * 0.55, r * 0.95, r * 0.38, Color(0, 0, 0, 0.18))
	Paint.fill_rr(self, x - 5, y - 4, 10, r * 0.6 + 4, 3, C("#6b4423"))
	Paint.circ(self, x, y - r * 0.55, r, C("#3f8f35"))
	Paint.circ(self, x - r * 0.3, y - r * 0.85, r * 0.6, C("#4fa843"))
	Paint.circ(self, x - r * 0.4, y - r, r * 0.25, Color(1, 1, 1, 0.12))

func draw_corn_plant(x: float, y: float) -> void:
	draw_line(Vector2(x, y + 6), Vector2(x, y - 18), C("#3f8f35"), 3)
	var leaf := C("#4fa843")
	Paint.poly(self, [Vector2(x, y - 2), Vector2(x - 10, y - 6), Vector2(x - 16, y - 16), Vector2(x - 6, y - 10), Vector2(x, y - 6)], leaf)
	Paint.poly(self, [Vector2(x, y - 4), Vector2(x + 10, y - 8), Vector2(x + 16, y - 18), Vector2(x + 6, y - 12), Vector2(x, y - 8)], leaf)
	Paint.ell(self, x + 4, y - 15, 4.5, 8, C("#f6c933"))

func draw_wheat_plant(x: float, y: float) -> void:
	for dx in [-7.0, 0.0, 7.0]:
		draw_line(Vector2(x + dx * 0.4, y + 6), Vector2(x + dx, y - 16), C("#c99a2e"), 2)
		Paint.ell(self, x + dx, y - 19, 3, 7, C("#f0c24a"))

func draw_apple_tree(x: float, y: float) -> void:
	draw_rect(Rect2(x - 2.5, y - 8, 5, 14), C("#7a4a2a"))
	Paint.circ(self, x, y - 18, 15, C("#3f9b3a"))
	Paint.circ(self, x - 4, y - 22, 8, C("#57b84a"))
	for fruit in [Vector2(-7, -14), Vector2(6, -20), Vector2(3, -10)]:
		Paint.circ(self, x + fruit.x, y + fruit.y, 3.2, C("#e23b3b"))

## Vehicle shop / armory / bank: out of the slice, drawn as closed shops (provisional).
func draw_shop_building(m) -> void:
	var s = m.shop
	var names := {"garage": ["VEHICLES", "#c0504d", "🚲"], "armory": ["ARMORY", "#6a4c93", "🔫"], "bank": ["BANK", "#2e8b57", "🏦"]}
	var n: Array = names[m.type]
	Paint.fill_rr(self, s.x + 3, s.y + 8, s.w, s.h, 10, Color(0, 0, 0, 0.18))
	Paint.fill_rr(self, s.x, s.y, s.w, s.h, 10, C("#f3e3bf"))
	Paint.fill_rr(self, s.x - 6, s.y - 10, s.w + 12, 22, 8, C(n[1]))
	Paint.text(self, n[0], s.x + s.w / 2, s.y + 1, 14, Color.WHITE)
	Paint.emoji_at(self, n[2], s.x + s.w / 2, s.y + 48, 28)
	Paint.text(self, "Carry products to shoot" if m.type == "armory" else "Coming soon", m.ox + MooSim.CW / 2, m.oy + 240, 18, Color(1, 1, 1, 0.85), Color(40 / 255.0, 25 / 255.0, 10 / 255.0, 0.45))

func draw_belt(b) -> void:
	var x0: float = minf(b.x1, b.x2)
	var w: float = b.len
	var y: float = b.y
	Paint.fill_rr(self, x0 - 4, y - 10, w + 8, 26, 8, Color(0, 0, 0, 0.18))
	Paint.fill_rr(self, x0 - 4, y - 14, w + 8, 26, 8, C("#244c9e"))
	Paint.fill_rr(self, x0 - 2, y - 12, w + 4, 20, 7, C("#3d74e0"))
	var moving: bool = b.items.size() > 0 and b.items[0] < b.len
	var off := fmod(sim.T * b.speed, 16.0) if moving else 0.0
	var k := 0.0
	while k < w:
		var x: float = x0 + fmod(k + off, w) if b.dir > 0 else x0 + w - fmod(k + off, w)
		draw_line(Vector2(x, y - 11), Vector2(x, y + 7), Color(1, 1, 1, 0.22), 2)
		k += 16
	Paint.fill_rr(self, b.x1 - b.dir * 6 - 8, y - 20, 16, 36, 4, C("#5b6472"))
	drop_pad(b.start, b.item)
	for pos in b.items:
		Paint.item(self, b.item, b.x1 + b.dir * pos, y + 5, 0.9)

func draw_bench(m) -> void:
	var b = m.bench
	Paint.fill_rr(self, b.x, b.y + 8, b.w, b.h + 4, 6, C("#8f5a2c"))
	Paint.fill_rr(self, b.x, b.y, b.w, b.h, 6, C("#c98a4b"))
	var y: float = b.y + 12
	while y < b.y + b.h:
		draw_line(Vector2(b.x + 4, y), Vector2(b.x + b.w - 4, y), Color(120 / 255.0, 70 / 255.0, 30 / 255.0, 0.45), 1.5)
		y += 12
	draw_pile(m.box)
	Paint.text(self, m.name, b.x + b.w - 48, b.y + b.h + 7, 12, C("#fff3dc"))

func draw_lamp(m) -> void:
	var b = m.bench
	var x: float = b.x + 8
	var y: float = b.y - 6
	draw_rect(Rect2(x - 2, y - 60, 4, 62), C("#3b3f4b"))
	Paint.circ(self, x, y - 62, 7, C("#cfd6de"))

func draw_pad(pd) -> void:
	var prog: float = float(pd.paid) / pd.cost
	var gate: bool = pd.fx == "gate"
	var base := C("#d08a1a" if gate else "#3c8a3c")
	var fill := C("#f5b942" if gate else "#6cc46c")
	var edge := C("#8a5a10" if gate else "#2a6a2a")
	var can: bool = sim.wallet() >= pd.cost - pd.paid
	var pulse := 1.0 + sin(sim.T * 6) * 0.03 if can else 1.0
	var c := MooSim.ctr(pd)
	var w: float = pd.w * pulse
	var h: float = pd.h * pulse
	var x: float = c.x - w / 2
	var y: float = c.y - h / 2
	Paint.fill_rr(self, x + 2, y + 5, w, h, 12, Color(0, 0, 0, 0.18))
	Paint.fill_rr(self, x, y, w, h, 12, base)
	if prog > 0:
		Paint.fill_rr(self, x, y + h * (1 - prog), w, h * prog, minf(12, h * prog / 2), fill)
	Paint.stroke_rr(self, x, y, w, h, 12, C("#ffe14d") if can else edge, 3)
	if pd.icon in ["⚙️", "💪", "🐄", "🐔", "🥚", "🧑‍🌾", "👨‍🌾", "✨", "🏡"]:
		Paint.emoji_at(self, pd.icon, c.x, c.y + (6 if gate else 2) - 12 * (1.5 if gate else 0.95), 24 * (1.5 if gate else 0.95))
	Paint.item(self, "coin", c.x - 24, y + h - 6, 0.8)
	Paint.text(self, MooSim.fmt(pd.cost - pd.paid), c.x + 8, y + h - 15, 18, Color.WHITE, Color(0, 0, 0, 0.3))
	Paint.text(self, pd.get("label",pd.name), c.x, y - 11, 17 if gate else 13, Color.WHITE, Color(40 / 255.0, 25 / 255.0, 10 / 255.0, 0.6))

func draw_fog(c) -> void:
	if c.fog <= 0.01:
		return
	var a: float = c.fog
	draw_rect(Rect2(c.x - 8, c.y - 8, c.w + 16, c.h + 16), C("#d9e8d2", a))
	var s: int = c.seed
	for i in 9:
		var x: float = c.x + MooSim.hash01(s + i * 3) * c.w
		var y: float = c.y + MooSim.hash01(s + i * 5 + 1) * c.h
		var r := 50 + MooSim.hash01(s + i * 11) * 50
		# clip to the cell (+8) like the prototype's ctx.clip()
		var cx := clampf(x + sin(sim.T * 0.3 + i) * 6, c.x - 8 + r, c.x + c.w + 8 - r)
		Paint.circ(self, cx, clampf(y, c.y - 8 + r, c.y + c.h + 8 - r), r, C("#f3f8ef", a))

func draw_cow(a) -> void:
	var x: float = a.x
	var y: float = a.y
	var f: float = a.face
	var bob := sin(sim.T * 20) * 1.5 if a.eat > 0 else 0.0
	Paint.ell(self, x, y, 28, 8, Color(0, 0, 0, 0.18))
	for lx in [-16, -7, 7, 16]:
		draw_rect(Rect2(x + lx - 2.5, y - 12, 5, 12), C("#3a2a2a"))
	draw_polyline(PackedVector2Array([Vector2(x - f * 25, y - 22), Vector2(x - f * 31, y - 14), Vector2(x - f * 29, y - 6)]), C("#3a2a2a"), 2)
	Paint.ell(self, x, y - 20, 26, 15, C("#fbfbfb"))
	for s in a.spots:
		# spots clipped to the body ellipse (approx: shrink into it)
		var sx: float = clampf(s[0], -26 + s[2], 26 - s[2])
		var sy: float = clampf(s[1], -15 + s[3], 15 - s[3])
		Paint.ell(self, x + sx, y - 20 + sy, s[2], s[3], C("#2b2b2b"))
	var hx := x + f * 25
	var hy := y - 25 + bob
	var horn := C("#f3e3c3")
	Paint.poly(self, [Vector2(hx - 5, hy - 8), Vector2(hx - 8, hy - 15), Vector2(hx - 1, hy - 9)], horn)
	Paint.poly(self, [Vector2(hx + 5, hy - 8), Vector2(hx + 8, hy - 15), Vector2(hx + 1, hy - 9)], horn)
	Paint.ell(self, hx, hy, 11, 10, C("#fbfbfb"))
	Paint.ell(self, hx - f * 3, hy - 4, 5, 4, C("#2b2b2b"))
	Paint.ell(self, hx + f * 6, hy + 5, 7, 5.5, C("#f4a3b4"))
	Paint.circ(self, hx + f * 4, hy + 5, 1.2, C("#b05a6a"))
	Paint.circ(self, hx + f * 8, hy + 5, 1.2, C("#b05a6a"))
	Paint.circ(self, hx + f * 2, hy - 2, 1.6, C("#1d1d1d"))

func draw_hen(a) -> void:
	var x: float = a.x
	var y: float = a.y
	var f: float = a.face
	var bob := absf(sin(sim.T * 18)) * 3 if a.eat > 0 else 0.0
	Paint.ell(self, x, y, 11, 4, Color(0, 0, 0, 0.18))
	draw_line(Vector2(x - 3, y - 6), Vector2(x - 3, y), C("#e8952b"), 2)
	draw_line(Vector2(x + 3, y - 6), Vector2(x + 3, y), C("#e8952b"), 2)
	Paint.ell(self, x, y - 12, 11, 8.5, C("#fffdf7"))
	Paint.ell(self, x - f * 3, y - 12, 6, 4, C("#ece6d6"))
	var hx := x + f * 8
	var hy := y - 20 + bob
	Paint.circ(self, hx, hy, 5.5, C("#fffdf7"))
	Paint.circ(self, hx, hy - 6, 2.5, C("#e23b3b"))
	Paint.circ(self, hx - f * 2.5, hy - 5, 2.2, C("#e23b3b"))
	Paint.poly(self, [Vector2(hx + f * 4, hy - 1), Vector2(hx + f * 9, hy + 1), Vector2(hx + f * 4, hy + 2.5)], C("#f0a030"))
	Paint.circ(self, hx + f * 1.5, hy - 1, 1.2, C("#1d1d1d"))

## Prototype drawUnit: stationary production machines bounce while working.
func draw_unit(m, u) -> void:
	var x: float = u.x
	var y: float = u.y
	var b: float = sin(u.anim * PI * 4) * 3 if u.anim > 0 else 0.0
	Paint.ell(self, x, y, 26, 7, Color(0, 0, 0, 0.2))
	Paint.fill_rr(self, x - 23, y - 30, 46, 30, 8, C("#3b3f4b"))
	Paint.fill_rr(self, x - 23, y - 36 + b, 46, 30, 8, C(m.get("color", "#7d8796")))
	Paint.fill_rr(self, x - 19, y - 33 + b, 38, 8, 4, Color(1, 1, 1, 0.25))
	Paint.item(self, m.get("icon", "⚙️"), x, y - 8 + b, 0.9)
	var pr := minf(1.0, u.timer / m.period)
	if MooSim.avail(m.hopper) > 0 or pr < 1:
		Paint.fill_rr(self, x - 18, y + 5, 36, 5, 2.5, Color(0, 0, 0, 0.35))
		Paint.fill_rr(self, x - 18, y + 5, 36 * pr, 5, 2.5, C("#7ed957"))

func draw_stack(e, cap: int) -> void:
	var st = e.stack
	var v: int = maxi(0, st.n - st.inc)
	if st.type == null or v <= 0:
		return
	var h: float = MooData.ITEMS[st.type].sh
	e.lean = e.get("lean", 0.0) + ((e.get("vx", 0.0) / 230.0) - e.get("lean", 0.0)) * 0.12
	for i in v:
		var pos := sim.stack_pos(e, i)
		Paint.item(self, st.type, pos.x, pos.y)
	if cap > 0 and st.n >= cap:
		Paint.text(self, "MAX", e.x + e.face * 12, e.y - 34 - v * h, 15, C("#ff4d3d"), Color.WHITE)

## drawCust + drawTurning (L1499, L1821): customers slowly turn green while they wait.
func draw_cust(c) -> void:
	var t := clampf(c.wait / c.patience, 0, 1)
	var skin := C(c.skin)
	if sim.real_night() and t >= 0.25:
		skin = skin.lerp(C("#7fb04a"), clampf((t - 0.25) / 0.55, 0, 1))
	var o: Dictionary = c.duplicate()
	o.skin = skin
	Paint.person(self, c.x, c.y + (3 if t > 0.6 else 0), o)
	for i in mini(c.got, 6):
		Paint.item(self, c.item, c.x + c.face * 11, c.y - 20 - i * MooData.ITEMS[c.item].sh * 0.75, 0.75)

func speech(e, dy: float) -> void:
	if e.get("say") == null:
		return
	var t: String = e.say.text
	var w := Paint.text_width(t, 13) + 16
	var x: float = e.x
	var y: float = e.y - dy
	var a := minf(1.0, e.say.t * 3)
	Paint.fill_rr(self, x - w / 2, y - 12, w, 24, 12, Color(1, 1, 1, a))
	Paint.poly(self, [Vector2(x - 5, y + 11), Vector2(x, y + 18), Vector2(x + 5, y + 11)], Color(1, 1, 1, a))
	Paint.text(self, t, x, y + 1, 13, C("#3a2412", a))

func player_look() -> Dictionary:
	return MooData.PLAYER_LOOK.duplicate()

func _draw() -> void:
	if sim == null:
		return
	var draw_start := Time.get_ticks_usec()
	Paint.next_frame()
	var V := vis_rect
	draw_rect(V, C(THEME0))
	# grass tufts
	var tx0 := floorf(V.position.x / 600) * 600
	var ty0 := floorf(V.position.y / 600) * 600
	var gx := tx0
	while gx < V.end.x:
		var gy := ty0
		while gy < V.end.y:
			draw_multiline(Transform2D(0.0, Vector2(gx, gy)) * grass_lines, Color(0, 0, 0, 0.06), 2)
			gy += 600
		gx += 600
	# paths along cell borders
	var path_col := C("#d4b98c")
	for c in sim.cells:
		if c.on and vis(c):
			draw_rect(Rect2(c.x - 7, c.y + c.h - 7, c.w + 14, 14), path_col)
			draw_rect(Rect2(c.x + c.w - 7, c.y - 7, 14, c.h + 14), path_col)
			draw_rect(Rect2(c.x - 7, c.y - 7, c.w + 14, 14), path_col)
			draw_rect(Rect2(c.x - 7, c.y - 7, 14, c.h + 14), path_col)
	for c in sim.cells:
		if vis(c) and c.fog < 1:
			if c.mod != null:
				draw_module(c.mod)
			else:
				draw_decor(c)
	for b in sim.belts:
		draw_belt(b)
	var L := sim.live()
	for m in L:
		if m.has("bin") and vis(m.bin):
			var b = m.bin
			Paint.fill_rr(self, b.x + 3, b.y + 6, b.w, b.h, 10, Color(0, 0, 0, 0.18))
			Paint.fill_rr(self, b.x, b.y, b.w, b.h, 10, C("#6d7f8c"))
			Paint.fill_rr(self, b.x - 3, b.y - 4, b.w + 6, 12, 5, C("#8fa3b1"))
			Paint.emoji_at(self, "🗑️", b.x + b.w / 2, b.y + b.h / 2 + 15 - 12 * 0.8, 24 * 0.8)
			label("Toss", b.x + b.w / 2, b.y - 14, 12)
	for pd in sim.visible_pads():
		if vis(pd):
			draw_pad(pd)
	# y-sorted entities
	var ents: Array = []
	for cell in sim.cells:
		if cell.on and cell.mod == null and vis(cell):
			for decoration in cell.get("decor", []):
				if decoration.kind == "tree":
					ents.append([decoration.y + decoration.r * 0.4, "tree", decoration])
	for m in L:
		if not vis(m.cell):
			continue
		if m.type == "machine":
			for u in m.units:
				if m.kind == "station":
					ents.append([u.y, "unit", {"m": m, "u": u}])
				else:
					ents.append([u.y, "cow" if m.kind == "cow" else "hen", u])
		if m.type == "counter":
			ents.append([m.bench.y + m.bench.h, "bench", m])
			ents.append([m.bench.y - 5, "lamp", m])
			for c in m.q:
				ents.append([c.y, "cust", c])
	# People elsewhere on the map are skipped; the margin covers their tallest
	# carried stack, speech and smile above the feet (ADR 0024).
	var near := V.grow(140) if cull_people else Rect2(-1e9, -1e9, 2e9, 2e9)
	for c in sim.leaving:
		if near.has_point(Vector2(c.x, c.y)):
			ents.append([c.y, "cust", c])
	for z in sim.zombies:
		if vis({"x":z.x-60,"y":z.y-140,"w":160,"h":150}): ents.append([z.y,"zombie",z])
	for h in sim.helpers:
		if near.has_point(Vector2(h.x, h.y)):
			ents.append([h.y, "helper", h])
	ents.append([sim.player.y, "player", sim.player])
	ents.sort_custom(func(a, b): return a[0] < b[0])
	for e in ents:
		var o = e[2]
		match e[1]:
			"tree": draw_tree(o)
			"cow": draw_cow(o)
			"hen": draw_hen(o)
			"unit": draw_unit(o.m, o.u)
			"bench": draw_bench(o)
			"lamp": draw_lamp(o)
			"cust": draw_cust(o)
			"zombie": ZombiePaint.draw_actor(self, o, sim.T)
			"helper":
				var look: Dictionary = o.look.duplicate()
				look.merge({"walk": o.walk, "moving": o.moving, "face": o.face}, true)
				Paint.person(self, o.x, o.y, look)
				draw_stack(o, 0)
			"player":
				var pl := player_look()
				pl.merge({"walk": o.walk, "moving": o.moving, "face": o.face}, true)
				Paint.person(self, o.x, o.y, pl)
				draw_stack(o, sim.S.cap)
	# Reuse cached item sprites for projectiles; aim and muzzle are cheap primitives.
	for shot in sim.shots: Paint.item(self,shot.item,shot.x,shot.y,0.8)
	if sim.S.gun > 0:
		var origin := Vector2(sim.player.x,sim.player.y-30)
		var direction := sim.aim_in.normalized()
		if direction.length() > 0:
			draw_line(origin+direction*22,origin+direction*sim.weapon_stats().range,C("#ffd54a",0.4),2)
			Paint.fill_rr(self,origin.x-8,origin.y-7,16,14,3,C("#6a4c93"))
			if sim.combat.muzzle > 0: Paint.circ(self,origin.x+direction.x*24,origin.y+direction.y*24,9,C("#fff7bd"))
	# bubbles: hungry machines, customers' wants with a patience ring
	for m in L:
		if not vis(m.cell):
			continue
		if m.type == "machine" and MooSim.avail(m.hopper) <= 0 and m.units.size():
			var u = m.units[0]
			Paint.bubble(self, u.x + (u.face * 20 if m.kind == "cow" else 0), u.y - (44 if m.kind == "hen" else 62), m["in"])
		if m.type == "counter":
			for i in m.q.size():
				var c = m.q[i]
				if (i < 2 and c.at) or i == 0:
					var tt := clampf(c.wait / c.patience, 0, 1)
					var col := C("#7ed957") if tt < 0.4 else (C("#ffb020") if tt < 0.7 else C("#ff3b30"))
					draw_arc(Vector2(c.x, c.y - 84), 24, -PI / 2, -PI / 2 + TAU * (1 - tt), 32, col, 4, true)
					Paint.bubble(self, c.x, c.y - 84, m.item, c.want - c.got)
	for m in L:
		if m.type == "counter" and vis(m.cell):
			draw_pocket_meter(m)
			var r := int(round(m.rep))
			Paint.text(self, "★".repeat(r) + "☆".repeat(5 - r), m.bench.x + 50, m.bench.y + m.bench.h + 7, 11, C("#ffd54a"), Color(60 / 255.0, 30 / 255.0, 0, 0.5))
	for c in sim.leaving:
		if c.happy > 0 and c.get("say") == null:
			Paint.circ(self, c.x, c.y - 82, 17, Color.WHITE)
			Paint.emoji_at(self, "😄", c.x, c.y - 82 + 12 * 0.85 - 12 * 0.85, 24 * 0.85)
	for c in sim.ground:
		var p := minf(1.0, c.ft / 0.35)
		var x: float = c.fx + (c.x - c.fx) * p
		var y: float = c.fy + (c.y - c.fy) * p - sin(PI * p) * 40
		if c.t > 3 or sin(sim.T * 20) > 0:
			Paint.item(self, "coin", x, y, 1.1)
	for m in L:
		if m.type == "counter":
			for c in m.q:
				speech(c, 112)
	for c in sim.leaving:
		speech(c, 100)
	for z in sim.zombies: speech(z, 100)
	speech(sim.player, 108)
	for f in sim.flyers:
		var pose := sim.flight_pose(f)
		Paint.item(self, f.type, pose.x, pose.y, pose.scale, pose.alpha)
	for f in sim.floaters:
		var a := maxf(0.0, 1 - maxf(0.0, f.t - 0.7) / 0.5)
		Paint.text(self, f.text, f.x, f.y - f.t * 40, 22, C("#ffd54a", a), C("#7a4a10", a))
	for sp in sim.sparks:
		Paint.circ(self, sp.x, sp.y, 4, C(sp.col, maxf(0.0, 1 - sp.t / 0.9)))
	# fog on top of everything that is not yet part of your world
	for c in sim.cells:
		if vis(c):
			draw_fog(c)
	var B = sim.bounds if sim.bounds != null else sim.target_bounds
	var fogc := C("#d9e8d2")
	draw_rect(Rect2(V.position.x, V.position.y, B.x0 - V.position.x, V.size.y), fogc)
	draw_rect(Rect2(B.x1, V.position.y, V.end.x - B.x1, V.size.y), fogc)
	draw_rect(Rect2(V.position.x, V.position.y, V.size.x, B.y0 - V.position.y), fogc)
	draw_rect(Rect2(V.position.x, B.y1, V.size.x, V.end.y - B.y1), fogc)
	draw_guide()
	draw_cpu_us = Time.get_ticks_usec() - draw_start

func draw_pocket_meter(m) -> void:
	var r = m.cash.rect
	var f := minf(1.0, m.cash.val / sim.pocket_cap(m))
	var x: float = r.x
	var y: float = r.y + r.h + 6
	var w: float = r.w
	Paint.fill_rr(self, x, y, w, 7, 3.5, Color(0, 0, 0, 0.35))
	var col := C("#ff4d3d") if f >= 0.8 else (C("#ffb020") if f >= 0.5 else C("#7ed957"))
	Paint.fill_rr(self, x, y, w * f, 7, 3.5, col)
	if f >= 1 and sin(sim.T * 10) > 0:
		Paint.text(self, "FULL!", x + w / 2, y + 18, 12, C("#ff4d3d"), Color.WHITE)

## guide arrow (L1735): bouncing arrow over the target, or a pointer at the player when off screen.
func draw_guide() -> void:
	if Moo.paused:
		return
	var g = sim.guide_target()
	var p = sim.player
	if g == null or MooSim.dist(g, p) <= 60:
		return
	var vs := view_size() / zoom
	var on_screen: bool = g.x > cam.x + 20 and g.x < cam.x + vs.x - 20 and g.y > cam.y + 60 and g.y < cam.y + vs.y - 20
	var fill := C("#ffe14d")
	var edge := C("#a5560f")
	if on_screen:
		var b := absf(sin(sim.T * 5)) * 10
		var y: float = g.y - 38 - b
		var pts := [Vector2(g.x - 14, y - 14), Vector2(g.x + 14, y - 14), Vector2(g.x + 14, y - 2), Vector2(g.x + 22, y - 2), Vector2(g.x, y + 16), Vector2(g.x - 22, y - 2), Vector2(g.x - 14, y - 2)]
		Paint.poly(self, pts, fill)
		var cl := PackedVector2Array(pts); cl.append(pts[0])
		draw_polyline(cl, edge, 3, true)
	else:
		var a := atan2(g.y - p.y, g.x - p.x)
		var c := Vector2(p.x + cos(a) * 70, p.y - 30 + sin(a) * 70)
		var pts := [Vector2(18, 0), Vector2(-10, -14), Vector2(-4, 0), Vector2(-10, 14)]
		var tp := []
		for q in pts:
			tp.append(c + q.rotated(a))
		Paint.poly(self, tp, fill)
		var cl := PackedVector2Array(tp); cl.append(tp[0])
		draw_polyline(cl, edge, 3, true)

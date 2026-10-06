class_name Paint
extends RefCounted
## Canvas-2D-style drawing helpers on top of CanvasItem.draw_* so the
## prototype's ctx code (rr, ell, circ, text, sprites) ports line by line (ADR 0005 G2).

static var font: FontVariation
static var emoji: SystemFont
static var item_textures := {}
static var item_baking := false
static var round_points := {}
static var ellipse_points := {}
static var color_cache := {}
static var text_sizes := {}

# Bake the existing procedural item drawings once, at 4x logical resolution.
# No external artwork; translucent flyers keep their original drawing path.
class ItemStamp extends Node2D:
	var kind := ""
	func _draw() -> void:
		draw_set_transform(Vector2(96, 128), 0.0, Vector2(4, 4))
		match kind:
			"corn": Paint.sh_corn(self, 1.0)
			"milk": Paint.sh_milk(self, 1.0)
			"egg": Paint.sh_egg(self, 1.0)
			"coin": Paint.sh_coin(self, 1.0)
			"cheese": Paint.sh_cheese(self, 1.0)
			"wheat": Paint.sh_wheat(self, 1.0)
			"bread": Paint.sh_bread(self, 1.0)
			"apple": Paint.sh_apple(self, 1.0)
			"pie": Paint.sh_pie(self, 1.0)

static func prime_items(parent: Node) -> void:
	if item_baking or not item_textures.is_empty() or DisplayServer.get_name() == "headless":
		return
	item_baking = true
	var views := {}
	for kind in ["corn", "milk", "egg", "coin", "cheese", "wheat", "bread", "apple", "pie"]:
		var view := SubViewport.new()
		view.size = Vector2i(192, 192)
		view.transparent_bg = true
		view.disable_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ONCE
		var stamp := ItemStamp.new()
		stamp.kind = kind
		view.add_child(stamp)
		parent.add_child(view)
		views[kind] = view
	await RenderingServer.frame_post_draw
	for kind in views:
		var view: SubViewport = views[kind]
		item_textures[kind] = ImageTexture.create_from_image(view.get_texture().get_image())
		view.queue_free()
	item_baking = false

static func fonts() -> void:
	if font == null:
		font = FontVariation.new()
		font.base_font = load("res://assets/fonts/Baloo2-Variable.ttf")
		font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
		emoji = SystemFont.new()
		emoji.font_names = PackedStringArray(["Apple Color Emoji", "Noto Color Emoji", "Segoe UI Emoji"])

static func C(hex: String, a: float = 1.0) -> Color:
	if not color_cache.has(hex):
		color_cache[hex] = Color(hex)
	var c: Color = color_cache[hex]
	c.a = a
	return c

static func rr_pts(x: float, y: float, w: float, h: float, r: float) -> PackedVector2Array:
	r = minf(r, minf(w, h) / 2.0)
	var key := Vector3(w, h, r)
	if round_points.has(key):
		return Transform2D(0.0, Vector2(x, y)) * round_points[key]
	var px := x; var py := y
	x = 0.0; y = 0.0
	var pts := PackedVector2Array()
	var corners := [[x + w - r, y + r, -PI / 2], [x + w - r, y + h - r, 0.0], [x + r, y + h - r, PI / 2], [x + r, y + r, PI]]
	for c in corners:
		for i in 6:
			var a: float = c[2] + (PI / 2) * i / 5.0
			pts.append(Vector2(c[0] + cos(a) * r, c[1] + sin(a) * r))
	if round_points.size() >= 512: round_points.clear()
	round_points[key] = pts
	return Transform2D(0.0, Vector2(px, py)) * pts

static func fill_rr(ci: CanvasItem, x: float, y: float, w: float, h: float, r: float, col: Color) -> void:
	if w <= 0.5 or h <= 0.5:
		return
	ci.draw_colored_polygon(rr_pts(x, y, w, h, r), col)

static func stroke_rr(ci: CanvasItem, x: float, y: float, w: float, h: float, r: float, col: Color, width: float) -> void:
	var p := rr_pts(x, y, w, h, r)
	p.append(p[0])
	ci.draw_polyline(p, col, width, true)

static func dash_rr(ci: CanvasItem, x: float, y: float, w: float, h: float, col: Color, width: float, dash: float) -> void:
	ci.draw_dashed_line(Vector2(x, y), Vector2(x + w, y), col, width, dash)
	ci.draw_dashed_line(Vector2(x + w, y), Vector2(x + w, y + h), col, width, dash)
	ci.draw_dashed_line(Vector2(x + w, y + h), Vector2(x, y + h), col, width, dash)
	ci.draw_dashed_line(Vector2(x, y + h), Vector2(x, y), col, width, dash)

static func ell_pts(x: float, y: float, rx: float, ry: float, seg: int = 22) -> PackedVector2Array:
	var key := Vector3(rx, ry, seg)
	if ellipse_points.has(key):
		return Transform2D(0.0, Vector2(x, y)) * ellipse_points[key]
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	if ellipse_points.size() >= 256: ellipse_points.clear()
	ellipse_points[key] = pts
	return Transform2D(0.0, Vector2(x, y)) * pts

static func ell(ci: CanvasItem, x: float, y: float, rx: float, ry: float, col: Color) -> void:
	if rx <= 0 or ry <= 0:
		return
	ci.draw_colored_polygon(ell_pts(x, y, rx, ry), col)

static func stroke_ell(ci: CanvasItem, x: float, y: float, rx: float, ry: float, col: Color, width: float) -> void:
	var p := ell_pts(x, y, rx, ry)
	p.append(p[0])
	ci.draw_polyline(p, col, width, true)

static func circ(ci: CanvasItem, x: float, y: float, r: float, col: Color) -> void:
	ci.draw_circle(Vector2(x, y), r, col)

static func poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), col)

## text(): centered on (x, y) like ctx textAlign=center/textBaseline=middle, outline = size/4.
static func text(ci: CanvasItem, t: String, x: float, y: float, size: float, fill: Color, stroke = null) -> void:
	fonts()
	var fs := int(round(size))
	var sz := measured(t, fs)
	var pos := Vector2(x - sz.x / 2.0, y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0)
	if stroke != null:
		ci.draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(size / 4.0) * 2), stroke)
	ci.draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fill)

static func text_width(t: String, size: float) -> float:
	fonts()
	return measured(t, int(round(size))).x

static func measured(t: String, fs: int) -> Vector2:
	var key := str(fs) + ":" + t
	if not text_sizes.has(key):
		if text_sizes.size() >= 1024: text_sizes.clear()
		text_sizes[key] = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	return text_sizes[key]

static func emoji_at(ci: CanvasItem, e: String, x: float, y: float, size: float, alpha: float = 1.0) -> void:
	fonts()
	var fs := int(round(size))
	var sz := emoji.get_string_size(e, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2(x - sz.x / 2.0, y + (emoji.get_ascent(fs) - emoji.get_descent(fs)) / 2.0)
	ci.draw_string(emoji, pos, e, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, alpha))

# ===== items & sprites (prototype L395-404) =====
## drawItem(t, x, y, s): code-drawn corn/milk/egg/coin, emoji for the rest.
static func item(ci: CanvasItem, t: String, x: float, y: float, s: float = 1.0, alpha: float = 1.0) -> void:
	if alpha == 1.0 and item_textures.has(t):
		ci.draw_texture_rect(item_textures[t], Rect2(x - 24 * s, y - 32 * s, 48 * s, 48 * s), false)
		return
	match t:
		"corn", "milk", "egg", "coin", "cheese", "wheat", "bread", "apple", "pie":
			ci.draw_set_transform(Vector2(x, y), 0.0, Vector2(s, s))
			match t:
				"corn": sh_corn(ci, alpha)
				"milk": sh_milk(ci, alpha)
				"egg": sh_egg(ci, alpha)
				"cheese": sh_cheese(ci, alpha)
				"wheat": sh_wheat(ci, alpha)
				"bread": sh_bread(ci, alpha)
				"apple": sh_apple(ci, alpha)
				"pie": sh_pie(ci, alpha)
				_: sh_coin(ci, alpha)
			ci.draw_set_transform(Vector2.ZERO)
		_:
			var e: String = MooData.ITEMS[t].e if MooData.ITEMS.has(t) else t
			emoji_at(ci, e, x, y - 12 * s, 24 * s, alpha)

static func sh_milk(ci: CanvasItem, a: float) -> void:
	fill_rr(ci, -6, -17, 12, 17, 4, C("#fdfdfd", a))
	stroke_rr(ci, -6, -17, 12, 17, 4, C("#b9c7d6", a), 1)
	fill_rr(ci, -4.5, -20.5, 9, 5, 1.5, C("#2d6be0", a))
	ci.draw_rect(Rect2(-6, -10, 12, 3), C("#2d6be0", a))
	ci.draw_rect(Rect2(-4, -15, 2, 4), Color(1, 1, 1, 0.9 * a))

static func sh_corn(ci: CanvasItem, a: float) -> void:
	poly(ci, [Vector2(-7, -4), Vector2(-15, -10), Vector2(-11, -4), Vector2(-15, 2)], C("#3f9b3a", a))
	ell(ci, 0, -4, 10, 4.2, C("#f6c933", a))
	stroke_ell(ci, 0, -4, 10, 4.2, C("#d49a12", a), 1)
	for i in range(-6, 7, 3):
		ci.draw_line(Vector2(i, -7.5), Vector2(i, -0.5), Color(180 / 255.0, 120 / 255.0, 10 / 255.0, 0.55 * a), 1)

static func sh_egg(ci: CanvasItem, a: float) -> void:
	ell(ci, 0, -7, 6, 7.5, C("#fff5e1", a))
	stroke_ell(ci, 0, -7, 6, 7.5, C("#d8c39c", a), 1)
	ell(ci, -2, -10, 1.8, 2.6, Color(1, 1, 1, 0.9 * a))

## A small cheese wedge, baked alongside the original procedural items.
static func sh_cheese(ci: CanvasItem, a: float) -> void:
	poly(ci, [Vector2(-10, -12), Vector2(10, -7), Vector2(10, 2), Vector2(-10, -3)], C("#e6a52b", a))
	poly(ci, [Vector2(-10, -12), Vector2(-1, -20), Vector2(10, -7)], C("#ffe47a", a))
	poly(ci, [Vector2(-10, -12), Vector2(10, -7), Vector2(10, -1), Vector2(-10, -6)], C("#f6c943", a))
	for hole in [Vector2(-5, -8), Vector2(3, -6), Vector2(6, -2)]:
		ell(ci, hole.x, hole.y, 1.8, 1.5, C("#c4861c", a))
	ell(ci, -1, -14, 2, 1.1, C("#dfb540", a))

## Bakery products keep their emoji silhouettes using cached procedural stamps.
static func sh_wheat(ci: CanvasItem, a: float) -> void:
	for dx in [-6.0, 0.0, 6.0]:
		ci.draw_line(Vector2(dx * 0.3, 0), Vector2(dx, -16), C("#c99a2e", a), 1.5)
		ell(ci, dx, -18, 2.5, 5, C("#f0c24a", a))
	ci.draw_line(Vector2(-4, -4), Vector2(4, -4), C("#986b29", a), 2)

static func sh_bread(ci: CanvasItem, a: float) -> void:
	fill_rr(ci, -11, -14, 22, 15, 5, C("#b96d28", a))
	fill_rr(ci, -11, -17, 22, 14, 6, C("#e9aa55", a))
	fill_rr(ci, -9, -15, 18, 9, 4, C("#f3c177", a))
	for dx in [-6.0, 0.0, 6.0]:
		ci.draw_line(Vector2(dx - 1.5, -13), Vector2(dx + 1.5, -9), C("#ffe4ac", a), 2)

static func sh_apple(ci: CanvasItem, a: float) -> void:
	ell(ci, -3.5, -8, 6.5, 8.5, C("#d93232", a))
	ell(ci, 3.5, -8, 6.5, 8.5, C("#e84b3d", a))
	ci.draw_line(Vector2(0, -15), Vector2(1, -21), C("#7a4a2a", a), 2)
	ell(ci, 4, -19, 4.5, 2, C("#59aa3d", a))
	ell(ci, -5, -11, 1.8, 3, Color(1, 1, 1, 0.5 * a))

static func sh_pie(ci: CanvasItem, a: float) -> void:
	ell(ci, 0, -3, 12, 5, C("#858e9d", a))
	ell(ci, 0, -5, 12, 5, C("#c98533", a))
	ell(ci, 0, -7, 11, 4.5, C("#e7b260", a))
	ell(ci, 0, -7, 8.5, 3.3, C("#a75b2b", a))
	for dx in [-5.0, 0.0, 5.0]:
		ci.draw_line(Vector2(dx - 2, -9), Vector2(dx + 2, -5), C("#f6cf83", a), 1.5)
	ci.draw_line(Vector2(-7, -7), Vector2(7, -7), C("#f6cf83", a), 1.5)

static func sh_coin(ci: CanvasItem, a: float) -> void:
	ell(ci, 0, -3, 8, 4, C("#c98a12", a))
	ell(ci, 0, -4.5, 8, 4, C("#f7c638", a))
	stroke_ell(ci, 0, -4.5, 8, 4, C("#e0a21c", a), 1)

## drawPerson (L1470)
static func person(ci: CanvasItem, x: float, y: float, o: Dictionary) -> void:
	ell(ci, x, y, 13, 5, Color(0, 0, 0, 0.18))
	var sw: float = sin(o.get("walk", 0.0)) * 4 if o.get("moving", false) else 0.0
	var f: float = o.get("face", 1)
	var pants := C(o.pants)
	fill_rr(ci, x - 8, y - 17 - maxf(0, sw), 7, 16, 3, pants)
	fill_rr(ci, x + 1, y - 17 - maxf(0, -sw), 7, 16, 3, pants)
	fill_rr(ci, x - 9, y - 4 - maxf(0, sw), 9, 5, 2, C("#3a2a20"))
	fill_rr(ci, x, y - 4 - maxf(0, -sw), 9, 5, 2, C("#3a2a20"))
	fill_rr(ci, x - 10, y - 36, 20, 22, 7, C(o.shirt))
	if o.get("vest"):
		fill_rr(ci, x - 10, y - 35, 6, 19, 3, C(o.vest))
		fill_rr(ci, x + 4, y - 35, 6, 19, 3, C(o.vest))
	var skin: Color = o.skin if o.skin is Color else C(o.skin)
	circ(ci, x - 11, y - 22, 3.5, skin)
	circ(ci, x + 11, y - 22, 3.5, skin)
	circ(ci, x, y - 46, 10, skin)
	var hair := C(o.hair)
	var hp := PackedVector2Array()
	for i in 9:
		var a := PI * 1.05 + (PI * 0.9) * i / 8.0
		hp.append(Vector2(x + cos(a) * 10.6, y - 47 + sin(a) * 10.6))
	hp.append(Vector2(x + 10, y - 48))
	ci.draw_colored_polygon(hp, hair)
	if o.get("bun", false):
		circ(ci, x - f * 8, y - 53, 5.5, hair)
	circ(ci, x + f * 3 - 2.6, y - 45, 1.3, C("#2b1d14"))
	circ(ci, x + f * 3 + 2.6, y - 45, 1.3, C("#2b1d14"))
	if o.get("hat", false):
		ell(ci, x, y - 52, 15, 5, C("#f2b84b"))
		ell(ci, x, y - 56, 9, 6, C("#f2b84b"))
		ci.draw_rect(Rect2(x - 9, y - 55, 18, 2.5), C("#d9534f"))
	if o.get("cap"):
		var cp := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			cp.append(Vector2(x + cos(a) * 10, y - 50 + sin(a) * 10))
		ci.draw_colored_polygon(cp, C(o.cap))
		ell(ci, x + f * 8, y - 50, 8, 3, C(o.cap))

## bubble (L1454)
static func bubble(ci: CanvasItem, x: float, y: float, ic: String, num = null) -> void:
	var w := 58.0 if num != null else 38.0
	fill_rr(ci, x - w / 2 + 2, y - 17, w, 36, 18, Color(0, 0, 0, 0.15))
	fill_rr(ci, x - w / 2, y - 19, w, 36, 18, Color.WHITE)
	poly(ci, [Vector2(x - 6, y + 15), Vector2(x, y + 24), Vector2(x + 6, y + 15)], Color.WHITE)
	if num != null:
		item(ci, ic, x - 13, y + 11, 0.95)
		text(ci, str(num), x + 14, y + 1, 20, C("#5a3a22"))
	else:
		item(ci, ic, x, y + 11, 1)

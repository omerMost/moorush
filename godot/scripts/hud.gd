extends Control
## HUD (prototype L1988): money pill, rank, saved flash, toasts, the touch
## joystick (L719-750) and the 3-slot menu (L2096-2140, trimmed to the slice).

var joy = null  # {id, s: Vector2, p: Vector2}
var menu: PanelContainer
var menu_box: VBoxContainer
var menu_btn: Button
var del_arm := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	menu_btn = Button.new()
	menu_btn.text = "☰"
	menu_btn.add_theme_font_size_override("font_size", 22)
	menu_btn.custom_minimum_size = Vector2(44, 44)
	menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_btn.position = Vector2(-56, 10)
	menu_btn.pressed.connect(func(): show_menu())
	add_child(menu_btn)
	build_menu()
	show_menu()

func _process(_dt: float) -> void:
	var s := Moo.sim
	var k := Vector2.ZERO
	if not Moo.paused:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): k.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): k.x += 1
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): k.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): k.y += 1
	var mv := k.normalized()
	if joy != null:
		var d: Vector2 = joy.p - joy.s
		if d.length() > 6:
			mv = d.normalized() * minf(1.0, d.length() / 45.0)
	s.move_in = mv
	queue_redraw()

func _input(e: InputEvent) -> void:
	if Moo.paused:
		return
	if e is InputEventScreenTouch:
		if e.pressed and joy == null:
			if menu_btn.get_global_rect().has_point(e.position):
				return
			joy = {"id": e.index, "s": e.position, "p": e.position}
		elif not e.pressed and joy != null and joy.id == e.index:
			joy = null
	elif e is InputEventScreenDrag and joy != null and joy.id == e.index:
		joy.p = e.position

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		joy = null

func _draw() -> void:
	var s := Moo.sim
	if s == null or Moo.paused:
		return
	var ink := Color(40 / 255.0, 25 / 255.0, 10 / 255.0, 0.55)
	# money pill
	var txt := MooSim.fmt(s.S.money)
	var w := Paint.text_width(txt, 21) + 54
	Paint.fill_rr(self, 10, 12, w, 36, 18, ink)
	Paint.circ(self, 30, 30, 13, Paint.C("#f5b921"))
	Paint.circ(self, 30, 28, 11, Paint.C("#ffe58a"))
	Paint.text(self, txt, 46 + (w - 54) / 2, 30, 21, Color.WHITE)
	# rank pill
	var rk := "Chapter 1 · Farm Kid"
	var rw := Paint.text_width(rk, 15) + 48
	var cx := size.x / 2
	Paint.fill_rr(self, cx - rw / 2, 56, rw, 28, 14, ink)
	Paint.emoji_at(self, "👦", cx - rw / 2 + 16, 70, 16)
	Paint.text(self, rk, cx + 10, 70, 15, Color.WHITE)
	if s.saved_flash > 0:
		Paint.text(self, "💾 Saved", 50, 64, 13, Color(1, 1, 1, minf(1.0, s.saved_flash * 2)), ink)
	# toasts (L1745)
	for i in s.toasts.size():
		var t = s.toasts[i]
		var a := maxf(0.0, minf(1.0, minf(t.t * 5, (t.dur - t.t) * 4)))
		var lines := wrap_text(t.text, 17, size.x - 60)
		var tw := 0.0
		for l in lines:
			tw = maxf(tw, Paint.text_width(l, 17))
		var h := 22.0 * lines.size() + 16
		var y := size.y - 150 - i * 52 - (h - 38)
		Paint.fill_rr(self, cx - tw / 2 - 17, y - 18, tw + 34, h, 19, Color(40 / 255.0, 25 / 255.0, 10 / 255.0, 0.8 * a))
		for j in lines.size():
			Paint.text(self, lines[j], cx, y + 2 + j * 22, 17, Color(1, 1, 1, a))
	# joystick
	if joy != null:
		var d: Vector2 = joy.p - joy.s
		var l := d.length()
		var kp: Vector2 = joy.s + (d / l * minf(l, 45.0) if l > 0 else Vector2.ZERO)
		Paint.circ(self, joy.s.x, joy.s.y, 48, Color(1, 1, 1, 0.22))
		Paint.circ(self, kp.x, kp.y, 22, Color(1, 1, 1, 0.65))

func wrap_text(t: String, fs: float, maxw: float) -> Array:
	var out := []
	var cur := ""
	for word in t.split(" "):
		var tryl := word if cur == "" else cur + " " + word
		if Paint.text_width(tryl, fs) > maxw and cur != "":
			out.append(cur)
			cur = word
		else:
			cur = tryl
	out.append(cur)
	return out

# ===== slot menu =====
func build_menu() -> void:
	menu = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Paint.C("#fff8e7")
	sb.set_corner_radius_all(26)
	sb.content_margin_left = 18; sb.content_margin_right = 18
	sb.content_margin_top = 18; sb.content_margin_bottom = 18
	menu.add_theme_stylebox_override("panel", sb)
	menu.set_anchors_preset(Control.PRESET_CENTER)
	add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 8)
	menu.add_child(menu_box)

func lbl(t: String, fs: int, col: String = "#3a2412") -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Paint.C(col))
	Paint.fonts()
	l.add_theme_font_override("font", Paint.font)
	return l

func btn(t: String, col: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(300, 46)
	b.add_theme_font_size_override("font_size", 18)
	Paint.fonts()
	b.add_theme_font_override("font", Paint.font)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Paint.C(col)
	sb.set_corner_radius_all(16)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	return b

func show_menu() -> void:
	Moo.open_menu()
	joy = null
	for c in menu_box.get_children():
		c.queue_free()
	menu_box.add_child(lbl("Moo Rush", 40, "#e0702a"))
	menu_box.add_child(lbl("Corn to Capitol · chapter-1 slice", 15))
	var s := Moo.sim
	for i in range(1, MooSim.SLOTS + 1):
		var d = s.read_slot(i)
		var head := "Slot %d" % i + (" · playing" if i == s.cur_slot else "")
		if d != null:
			var info := "👦 Farm Kid · 🪙 %s%s" % [MooSim.fmt(d.get("money", 0)), " · ✅ dairy bought" if d.get("done", false) else ""]
			menu_box.add_child(lbl(head + " — " + info, 15))
			var row := HBoxContainer.new()
			var play := btn("▶ Play", "#4caf50", func(): start(i))
			play.custom_minimum_size = Vector2(170, 44)
			row.add_child(play)
			var del := btn("Tap again to delete" if del_arm == i else "🗑 Delete", "#c9b48a", func(): delete(i))
			del.custom_minimum_size = Vector2(130, 44)
			row.add_child(del)
			menu_box.add_child(row)
		else:
			menu_box.add_child(lbl(head + " — Empty", 15))
			menu_box.add_child(btn("✨ New game here", "#f0a020", func(): start(i)))
	menu.visible = true
	menu_btn.visible = false
	await get_tree().process_frame
	menu.reset_size()
	menu.position = (size - menu.size) / 2

func start(i: int) -> void:
	del_arm = 0
	Moo.start_slot(i)
	menu.visible = false
	menu_btn.visible = true

func delete(i: int) -> void:
	if del_arm != i:
		del_arm = i
	else:
		del_arm = 0
		Moo.sim.delete_slot(i)
	show_menu()

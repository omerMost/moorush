extends RefCounted
## HUD-owned dual-stick input; no persistent state and no simulation ownership.
var aim = null
var mouse_down := false
var mouse_pos := Vector2.ZERO
var mouse_seen := false
var dash_btn: Button
var hud: Control

func _init(owner: Control) -> void: hud = owner

func ready() -> void:
	dash_btn = Button.new()
	dash_btn.name = "DashButton"; dash_btn.text = "Dash"
	dash_btn.custom_minimum_size = Vector2(72,48)
	Paint.fonts()
	dash_btn.add_theme_font_override("font",Paint.font)
	dash_btn.add_theme_font_size_override("font_size",16)
	var style := StyleBoxFlat.new()
	style.bg_color = Paint.C("#6a4c93")
	style.set_corner_radius_all(18)
	for state in ["normal","hover","pressed","disabled"]: dash_btn.add_theme_stylebox_override(state,style)
	dash_btn.pressed.connect(func():
		if active(): Moo.sim.dash_request = true)
	hud.add_child(dash_btn)

func active() -> bool: return not Moo.paused and not Moo.suspended and Moo.sim.faint == null

func clear() -> void:
	aim = null; mouse_down = false; mouse_seen = false
	Moo.sim.clear_combat_input()

func process() -> void:
	var s := Moo.sim
	dash_btn.position = Vector2(hud.size.x-92,hud.size.y-185)
	dash_btn.visible = active()
	dash_btn.text = "%.1f" % s.combat.dash_cd if s.combat.dash_cd > 0 else "Dash"
	dash_btn.disabled = s.combat.dash_cd > 0
	if not active(): clear(); return
	s.aim_in = Vector2.ZERO; s.fire_in = false
	if aim != null:
		var delta: Vector2 = aim.p-aim.s
		if delta.length() > 12:
			s.aim_in = delta.normalized(); s.fire_in = true
	elif mouse_seen and s.S.gun > 0:
		var world = hud.get_tree().root.find_child("World",true,false)
		if world:
			var point: Vector2 = world.get_global_transform().affine_inverse()*mouse_pos
			s.aim_in = (point-Vector2(s.player.x,s.player.y-30)).normalized()
			s.fire_in = mouse_down

# Returns true if combat owns this event; movement keeps its existing left ID.
func input(e: InputEvent) -> bool:
	if not active(): return false
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION: return true
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_SPACE,KEY_SHIFT]:
		Moo.sim.dash_request = true; return true
	if e is InputEventMouseMotion:
		mouse_pos = e.position; mouse_seen = true
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and dash_btn.get_global_rect().has_point(e.position): return true
		mouse_down = e.pressed; mouse_pos = e.position; mouse_seen = true
	if e is InputEventScreenTouch:
		if e.pressed and dash_btn.get_global_rect().has_point(e.position): return true
		if e.pressed and e.position.x >= hud.size.x/2 and Moo.sim.S.gun > 0:
			if aim == null: aim = {"id":e.index,"s":e.position,"p":e.position,"dragged":false}
			return true
		if not e.pressed and aim != null and aim.id == e.index:
			if not aim.dragged: Moo.sim.quick_shot = true
			aim = null; return true
	if e is InputEventScreenDrag and aim != null and aim.id == e.index:
		aim.p = e.position
		if (aim.p-aim.s).length() > 12: aim.dragged = true
		return true
	return false

func draw() -> void:
	var s := Moo.sim
	if s.S.gun > 0:
		var stats := s.weapon_stats()
		var ammo: int = MooSim.avail(s.player.stack)
		Paint.fill_rr(hud,12,hud.size.y-58,hud.size.x-24,34,17,Color(0.12,0.08,0.05,0.7))
		Paint.text(hud,"%s · Ammo %d · %s" % [stats.name,ammo,"Tap / hold to shoot"],hud.size.x/2,hud.size.y-41,14,Color.WHITE)
		if aim == null:
			Paint.circ(hud,hud.size.x-92,hud.size.y-100,42,Color(1,1,1,0.15))
			Paint.text(hud,"AIM",hud.size.x-92,hud.size.y-100,13,Color.WHITE)
	if aim != null:
		var delta: Vector2 = aim.p-aim.s
		var knob: Vector2 = aim.s+delta.limit_length(45)
		Paint.circ(hud,aim.s.x,aim.s.y,48,Color(1,0.75,0.4,0.25))
		Paint.circ(hud,knob.x,knob.y,22,Color(1,0.85,0.5,0.8))
	if s.combat.flash > 0: hud.draw_rect(Rect2(Vector2.ZERO,hud.size),Color(1,1,1,0.35*s.combat.flash/0.25))

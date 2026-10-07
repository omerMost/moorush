extends Node2D
## One overlay quad with bounded radial lights; no per-frame texture baking.
const MAX_LIGHTS := 24 # player + six counters + thirteen helpers fits with headroom.
var area := Rect2()
var tint := Color()
var shade := ShaderMaterial.new()

func _init() -> void:
	shade.shader = preload("res://scripts/night_lighting.gdshader")
	material = shade

func refresh(sim: MooSim, visible_area: Rect2) -> void:
	area = visible_area
	var amount := sim.darkness()
	visible = amount > 0.01
	if not visible: return
	tint = Color(70.0 / 255, 0, 12.0 / 255, amount) if sim.is_boss_night() else Color(8.0 / 255, 14.0 / 255, 48.0 / 255, amount)
	var lights := PackedVector4Array()
	lights.append(Vector4(sim.player.x, sim.player.y - 30, 170, 0.95))
	for m in sim.live():
		if m.type == "counter" and lights.size() < MAX_LIGHTS:
			lights.append(Vector4(m.bench.x + 8, m.bench.y - 60, 95, 0.9))
	for h in sim.helpers:
		if lights.size() < MAX_LIGHTS:
			lights.append(Vector4(h.x, h.y - 30, 70, 0.6))
	shade.set_shader_parameter("light_count", lights.size())
	lights.resize(MAX_LIGHTS)
	shade.set_shader_parameter("lights", lights)
	queue_redraw()

func _draw() -> void:
	draw_rect(area, tint)

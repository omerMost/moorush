class_name MooBot
extends RefCounted
## "Follow the arrow" bot: walks the player toward the game's own guide target
## (guideTarget, prototype L767) along findPath, through the real input path.

var sim: MooSim
var path: Array = []
var path_key := ""
var repath_t := 0.0

func _init(s: MooSim) -> void:
	sim = s

func tick(dt: float) -> void:
	var g = sim.guide_target()
	var p = sim.player
	if g == null:
		sim.test_in = Vector2.ZERO
		return
	var key := str(round(g.x)) + "," + str(round(g.y))
	repath_t -= dt
	if key != path_key or repath_t <= 0 or path.is_empty():
		var fp = sim.find_path(p.x, p.y, g.x, g.y)
		path = fp if fp != null else [{"x": g.x, "y": g.y}]
		path_key = key
		repath_t = 1.0
	while path.size() > 1 and Vector2(path[0].x - p.x, path[0].y - p.y).length() < 10:
		path.pop_front()
	var wp = path[0]
	var v := Vector2(wp.x - p.x, wp.y - p.y)
	sim.test_in = v.normalized() if v.length() > 6 else Vector2.ZERO

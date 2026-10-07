class_name MooFightBot
extends RefCounted
## Real inputs/harvesting/projectiles; no HP, ammo or wallet mutation while fighting.
var sim: MooSim
var corner := 0
var damage_taken := 0
var last_hearts := 5
var fired := 0
var prior_stock := 0

func _init(owner: MooSim) -> void: sim = owner

func tick() -> void:
	var p = sim.player
	var field = sim.mod_by("A",sim.S.ch)
	var r = field.rect
	var points := [Vector2(r.x+25,r.y+25),Vector2(r.x+r.w-25,r.y+25),Vector2(r.x+r.w-25,r.y+r.h-25),Vector2(r.x+25,r.y+r.h-25)]
	var goal: Vector2 = points[corner]
	if Vector2(p.x,p.y).distance_to(goal) < 18:
		corner = (corner+1)%4; goal = points[corner]
	sim.test_in = (goal-Vector2(p.x,p.y)).normalized()
	var nearest = null
	for z in sim.zombies:
		if nearest == null or MooSim.dist(z,p) < MooSim.dist(nearest,p): nearest = z
	if nearest != null:
		sim.aim_in = (Vector2(nearest.x,nearest.y-20)-Vector2(p.x,p.y-30)).normalized()
		sim.fire_in = MooSim.dist(nearest,p) <= sim.weapon_stats().range
		if MooSim.dist(nearest,p) < 75 and sim.combat.dash_cd <= 0:
			sim.dash_request = true
	else: sim.fire_in = false
	if sim.S.hearts < last_hearts: damage_taken += last_hearts-sim.S.hearts
	last_hearts = sim.S.hearts

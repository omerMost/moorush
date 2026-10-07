extends RefCounted
## Manual weapon fire, swept products, upgrades, dash and bounded combat feedback.
const SHOT_SPEED := 720.0
const CONE := 14.0 * PI / 180.0
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void: _owner = weakref(owner)

func clear_input() -> void:
	sim.aim_in = Vector2.ZERO; sim.fire_in = false
	sim.quick_shot = false; sim.dash_request = false
	if not sim.combat.is_empty():
		sim.combat.dash_t = 0.0; sim.combat.dash_mul = 1.0

func reset_combat() -> void:
	sim.S.gun = 0
	sim.S.gun_damage = [false,false,false]; sim.S.gun_speed = [false,false,false]
	sim.combat = {"cooldown":0.0, "dash_t":0.0, "dash_cd":0.0, "dash_x":1.0, "dash_y":0.0,
		"dash_mul":1.0, "empty_t":0.0, "muzzle":0.0, "combo":0, "combo_t":0.0, "hit_stop":0.0, "flash":0.0}
	sim.shots.clear(); clear_input()

func snapshot() -> Dictionary:
	# Flights and held input are ephemeral; spent ammo is already in the saved stack.
	return {"cooldown":sim.combat.cooldown, "dash_cd":sim.combat.dash_cd, "dash_t":sim.combat.dash_t,
		"dash_x":sim.combat.dash_x, "dash_y":sim.combat.dash_y}

func restore_combat(d: Dictionary) -> void:
	# Owned upgrades derive from pad replay, so retry rolls them back with payments.
	sim.S.gun = maxi(sim.S.gun, clampi(int(d.get("gun",0)),0,mini(3,sim.S.ch+1)))
	var saved = d.get("combat",{})
	if saved is Dictionary:
		for key in snapshot():
			var value := float(saved.get(key,sim.combat[key]))
			if is_finite(value): sim.combat[key] = value
	sim.combat.cooldown = clampf(sim.combat.cooldown,0,0.7)
	sim.combat.dash_cd = clampf(sim.combat.dash_cd,0,2.5)
	sim.combat.dash_t = clampf(sim.combat.dash_t,0,0.18)
	clear_input()

func weapon_stats(index: int = -1) -> Dictionary:
	if index < 0: index = int(sim.S.gun) - 1
	if index < 0 or index >= 3: return {}
	var stats: Dictionary = MooData.WEAPONS[index].duplicate()
	stats.damage *= 1.5 if sim.S.gun_damage[index] else 1.0
	stats.cd *= 0.75 if sim.S.gun_speed[index] else 1.0
	return stats

func try_dash() -> bool:
	if sim.faint != null or sim.combat.dash_cd > 1e-8: return false
	var direction := sim.test_in if sim.test_in.length() > 0.001 else sim.move_in
	if direction.length() < 0.001: direction = sim.aim_in
	if direction.length() < 0.001: direction = Vector2(sim.player.face,0)
	direction = direction.normalized()
	sim.combat.dash_x = direction.x; sim.combat.dash_y = direction.y
	sim.combat.dash_t = 0.18; sim.combat.dash_cd = 2.5
	sim.inv_t = maxf(sim.inv_t,0.33)
	sim.events.append({"kind":"drop"})
	return true

func timers(dt: float) -> void:
	var c = sim.combat
	for key in ["cooldown","dash_cd","empty_t","muzzle","combo_t","flash"]: c[key] = maxf(0,c[key]-dt)
	if c.combo_t <= 0: c.combo = 0
	if sim.dash_request: try_dash()
	sim.dash_request = false
	c.dash_mul = 1.0 + 1.6 * minf(dt,c.dash_t)/dt if dt > 0 else 1.0
	c.dash_t = maxf(0,c.dash_t-dt)

func target(direction: Vector2, radius: float, quick: bool = false):
	var best = null
	var score := INF
	var origin := Vector2(sim.player.x,sim.player.y-30)
	for z in sim.zombies:
		var delta := Vector2(z.x,z.y-20)-origin
		var distance := delta.length()
		if distance < 1 or distance > radius: continue
		var dot := delta.normalized().dot(direction)
		if not quick and dot < cos(CONE): continue
		var candidate := distance if quick else distance*(1-dot)
		if candidate < score: best = z; score = candidate
	return best

func update(dt: float) -> void:
	var stats := weapon_stats()
	if not stats.is_empty():
		var quick := sim.quick_shot
		var direction := sim.aim_in.normalized()
		var assisted = target(direction,stats.range,quick) if quick or direction.length() > 0 else null
		if assisted != null: direction = (Vector2(assisted.x,assisted.y-20)-Vector2(sim.player.x,sim.player.y-30)).normalized()
		if quick and assisted == null: direction = Vector2(sim.player.face,0)
		if direction.length() > 0:
			if absf(direction.x) > 0.2: sim.player.face = 1 if direction.x > 0 else -1
			if (sim.fire_in or quick) and sim.combat.cooldown <= 1e-8: fire(direction,stats,assisted)
	sim.quick_shot = false
	for i in range(sim.shots.size()-1,-1,-1):
		var shot = sim.shots[i]
		var start := Vector2(shot.x,shot.y)
		var step := minf(SHOT_SPEED*dt,shot.left)
		var direction := Vector2(shot.dx,shot.dy)
		# Gentle target magnetism lasts only the first 150ms, like the prototype.
		var actors := sim.zombies.filter(func(z): return z.id == shot.target)
		if shot.age < 0.15 and not actors.is_empty():
			var desired := (Vector2(actors[0].x,actors[0].y-20)-start).angle()
			direction = Vector2.from_angle(rotate_toward(direction.angle(),desired,12*dt))
			shot.dx = direction.x; shot.dy = direction.y
		var end := start+direction*step
		var hit = null
		var nearest := INF
		for z in sim.zombies:
			var center := Vector2(z.x,z.y-20)
			var point := Geometry2D.get_closest_point_to_segment(center,start,end)
			if point.distance_to(center) <= (30 if z.big else 26):
				var distance := start.distance_to(point)
				if distance < nearest: nearest = distance; hit = z
		shot.x = end.x; shot.y = end.y; shot.left -= step; shot.age += dt
		if hit != null:
			var impact := Vector2(hit.x,hit.y-20)
			var splash := sim.zombies.filter(func(z): return z != hit and Vector2(z.x,z.y-20).distance_to(impact) <= shot.splash)
			strike(hit,shot.damage,shot.item)
			if shot.splash > 0:
				for z in splash: strike(z,shot.splash_damage,shot.item)
		if hit != null or shot.left <= 1e-8: sim.shots.remove_at(i)

func fire(direction: Vector2, stats: Dictionary, assisted) -> bool:
	var st = sim.player.stack
	if MooSim.avail(st) <= 0:
		if sim.combat.empty_t <= 0:
			sim.combat.empty_t = 1.2
			sim.toast("No ammo! Carry a farm product.",1.6)
			sim.events.append({"kind":"warn"})
		return false
	# One settled item per shot, of any product; incoming stack tokens remain valid.
	var item: String = st.type
	st.n -= 1
	if st.n == 0: st.type = null
	sim.combat.cooldown = stats.cd; sim.combat.muzzle = 0.06
	sim.shots.append({"x":sim.player.x+direction.x*16,"y":sim.player.y-30+direction.y*16,
		"dx":direction.x,"dy":direction.y,"left":stats.range-16,"age":0.0,"item":item,
		"damage":stats.damage,"splash":stats.splash,"splash_damage":stats.splash_damage,
		"target":assisted.id if assisted != null else -1})
	sim.shake_amt = maxf(sim.shake_amt,1.5)
	sim.events.append({"kind":"pop"})
	return true

func strike(z, damage: float, item: String) -> void:
	if z not in sim.zombies: return
	var before: float = z.hp
	sim.hit_zombie(z,damage,item)
	z.flash = 0.08
	sim.combat.hit_stop = maxf(sim.combat.hit_stop,0.035)
	sim.shake_amt = maxf(sim.shake_amt,2)
	sim.floaters.append({"x":z.x,"y":z.y-70,"text":"-"+str(before-z.hp),"t":0.3})
	if z not in sim.zombies:
		sim.combat.hit_stop = 0.07
		sim.combat.combo += 1; sim.combat.combo_t = 1.6
		sim.S.stats.cures = int(sim.S.stats.get("cures",0))+1
		sim.events.append({"kind":"coin","pitch":1+mini(12,sim.combat.combo)*0.06})
		if sim.combat.combo > 1:
			sim.floaters.append({"x":sim.player.x,"y":sim.player.y-120,"text":"×%d COMBO!" % sim.combat.combo,"t":0.0})

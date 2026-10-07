extends RefCounted
## Night actors and scheduler. Combat consumes hit_zombie; hearts consume zombie_bite.
const CAP := 10
const HP := [3, 6, 12]
const DAMAGE := [1, 2, 4]
const TYPES := ["normal", "karen", "lactose", "vault", "influencer", "flag", "granny"]
const WEIGHTS := [39, 12, 11, 11, 11, 8, 8]
const SHIRTS := ["#d9534f", "#f0ad4e", "#5bc0de", "#8e44ad", "#ff5ea8"]
const MORNING_LINES := ["*yawn* what a night", "Morning already?", "Why do I want brains?"]
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()
var random: RandomNumberGenerator:
	get: return sim.night_rng
var serial: int:
	get: return sim.night_state.serial
	set(value): sim.night_state.serial = value
var beat: int:
	get: return sim.night_state.beat
	set(value): sim.night_state.beat = value
var elapsed: float:
	get: return sim.night_state.elapsed
	set(value): sim.night_state.elapsed = value
var path_cursor: int:
	get: return sim.night_state.cursor
	set(value): sim.night_state.cursor = value
var path_budget := 0 # Scratch budget for the current tick, not saved state.

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func reset_night(chapter_entry: bool = false) -> void:
	sim.zombies.clear()
	beat = -1
	elapsed = 0.0
	path_cursor = 0
	if not chapter_entry:
		serial = 0
		random.seed = sim.rng.seed ^ 0x4D4F4F
		sim.S.tut = {"gary": 0}
	elif sim.S.ch > 0 and sim.S.tut.gary < 2:
		sim.S.tut.gary = 2

func real_night() -> bool:
	return sim.is_night() and not (sim.S.ch == 0 and sim.S.cn == 1)

func begin_night() -> void:
	beat = -1
	elapsed = 0.0
	if real_night(): emit_beat(0)

func advance_night(dt: float) -> void:
	if not real_night(): return
	elapsed = minf(90.0, elapsed + dt)
	for next in [1, 2]:
		if beat < next and elapsed >= next * 30.0 - 1e-8:
			emit_beat(next)

func emit_beat(index: int) -> void:
	beat = index
	var first := 2 if sim.S.ch == 0 else 1
	var count := 2 + index * 2 + maxi(0, sim.S.cn - first)
	var spawned := 0
	for i in mini(count, CAP - sim.zombies.size()):
		if sim.horde_zombie() != null: spawned += 1
	sim.events.append({"kind": "night_beat", "beat": index, "requested": count, "spawned": spawned, "cn": sim.S.cn})

func evening_gary() -> void:
	if sim.S.ch != 0 or sim.S.day != 1 or sim.S.tut.gary != 0: return
	var field = sim.mod_by("A", 0)
	var p := free_point(field.rect.x + field.rect.w + 24, field.rect.y + field.rect.h + 30)
	var g := new_zombie(p.x, p.y, "gary", false, null, 0)
	g.shirt = "#c0504d"; g.pants = "#5b7aa5"; g.hair = "#e9c46a"; g.skin = "#d9b77a"
	sim.zombies.append(g)
	sim.S.tut.gary = 1
	sim.say(g, "Practice zombie. I'm straw.", 4.0)
	sim.toast("That's Gary. Practice zombie. He'll wait.", 3.0)

## Becomes active when the weapon port supplies the real Milk squirter pad.
func gary_guide():
	if sim.S.tut.gary != 1 or int(sim.S.get("gun",0)) > 0: return null
	for pad in sim.visible_pads():
		if pad.fx == "gun" and int(pad.get("v",0)) == 1 and sim.wallet() >= pad.cost-pad.paid:
			return MooSim.ctr(pad)
	return null

func pick_type() -> String:
	var roll := random.randi_range(1, 100)
	for i in TYPES.size():
		roll -= WEIGHTS[i]
		if roll <= 0: return TYPES[i]
	return "normal"

func free_point(x: float, y: float) -> Vector2:
	var cell := sim.nearest_free(sim.nav_gx(x), sim.nav_gy(y))
	return Vector2(sim.nav_cx(cell.x), sim.nav_cy(cell.y))

func new_zombie(x: float, y: float, type: String, big: bool, source, want: int) -> Dictionary:
	serial += 1
	var hp: int = HP[sim.S.ch]
	if type == "karen": hp = int(ceil(hp * 1.5))
	if type == "granny": hp += DAMAGE[sim.S.ch] * 2
	if big: hp *= 3
	if type == "gary": hp = 1
	return {"id": serial, "x": x, "y": y, "hp": hp, "max": hp, "type": type, "big": big,
		"shirt": SHIRTS[random.randi() % SHIRTS.size()], "pants": "#3d3d5c", "hair": "#2b1b10", "hat": false,
		"skin": "#7fb04a", "face": 1, "walk": 0.0, "moving": false, "src": source.key if source != null else "",
		"want": want, "item": source.item if source != null else "milk", "human_skin": "#f1c27d",
		"spd": 0.0, "state": "chase", "st": 0.0, "bite": 0.0, "slow": 0.0, "kbt": 0.0, "kbx": 0.0, "kby": 0.0,
		"say": null, "path": [], "repath": 0.0, "armed": 0.0, "infl_t": 3.0}

func horde_zombie():
	if not real_night() or sim.zombies.size() >= CAP: return null
	var point := Vector2.ZERO
	var found := false
	for attempt in 16:
		var angle := random.randf() * TAU
		var radius := 520.0 if attempt < 8 else 360.0
		point = free_point(sim.player.x + cos(angle) * radius, sim.player.y + sin(angle) * radius)
		if sim.walkable(point.x, point.y) and not sim.blocked_at(point.x, point.y):
			# Spawn must have a route into play; closed/fogged regions never get actors.
			var route = sim.find_path(point.x, point.y, sim.player.x, sim.player.y)
			found = route != null
			if found: break
	if not found: return null
	var counters := sim.live().filter(func(m): return m.type == "counter")
	var source = null
	for m in counters:
		if source == null or m.d == sim.S.ch: source = m
	var z := new_zombie(point.x, point.y, pick_type(), random.randf() < 0.2, source, 3)
	sim.zombies.append(z)
	return z

func turn_customer(c, m) -> bool:
	if not real_night() or sim.zombies.size() >= CAP or MooSim.dist(c, sim.player) >= 1100: return false
	var z := new_zombie(c.x, c.y, pick_type(), false, m, c.want)
	for key in ["shirt", "pants", "hair", "hat"]: z[key] = c[key]
	z.human_skin = c.skin
	sim.zombies.append(z)
	sim.say(z, "GRRR... too slow!", 2.2)
	sim.events.append({"kind": "customer_turned", "source": m.key, "id": z.id})
	return true

func unstick(z) -> void:
	if not sim.walkable(z.x, z.y) or sim.blocked_at(z.x, z.y, 8):
		var p := free_point(z.x, z.y)
		z.x = p.x; z.y = p.y; z.path = []; z.repath = 0.0

func safe_move(z, x: float, y: float, speed: float, dt: float) -> void:
	var previous := Vector2(z.x, z.y)
	sim.move_to(z, x, y, speed, dt)
	for obstacle in sim.near_obs(z.x, z.y, 60): sim.push_out(z, obstacle, 12)
	if not sim.walkable(z.x, z.y) or not sim.line_free(previous.x, previous.y, z.x, z.y):
		z.x = previous.x; z.y = previous.y; z.moving = false; z.repath = 0.0
	unstick(z)

func chase(z, dt: float) -> void:
	z.repath -= dt
	if z.repath <= 0.0 and path_budget > 0:
		path_budget -= 1
		var route = sim.find_path(z.x, z.y, sim.player.x, sim.player.y)
		z.path = route if route != null else []
		z.repath = 0.5 + random.randf() * 0.2
	# A failed/exhausted route waits for the next plan; never fall back to a straight chase.
	while not z.path.is_empty() and MooSim.dist(z, z.path[0]) < 4:
		z.path.pop_front()
	if z.path.is_empty(): z.moving = false; return
	safe_move(z, z.path[0].x, z.path[0].y, z.spd, dt)

func upd_zombies(dt: float) -> void:
	if dt <= 0.0: return
	path_budget = 4
	# Round-robin scheduling prevents four actors monopolising the replanning budget.
	var count := sim.zombies.size()
	for offset in count:
		var z = sim.zombies[(path_cursor + offset) % count]
		unstick(z)
		z.moving = false
		z.bite -= dt; z.slow -= dt
		if z.type == "gary":
			if int(sim.S.get("gun", 0)) == 0: continue
			z.armed += dt
			if z.armed >= 60.0:
				finish_gary(z, true)
				break # Removal changes indices; the next tick continues the round-robin.
			z.spd = MooSim.SPEED * 1.3 * 0.4
			if MooSim.dist(z, sim.player) > 40: chase(z, dt)
			continue
		if z.kbt > 0.0:
			z.kbt -= dt
			safe_move(z, z.x + z.kbx * dt, z.y + z.kby * dt, Vector2(z.kbx,z.kby).length(), dt)
			continue
		if z.state != "chase":
			z.st -= dt
			if z.st <= 0.0:
				if z.state == "windup":
					if MooSim.dist(z, sim.player) < 42:
						sim.zombie_bite(z)
						if sim.faint != null: return
					z.state = "recover"; z.st = 0.9; z.bite = 2.0
				else: z.state = "chase"
			continue
		var top := MooSim.SPEED * 1.3 * (0.8 if z.big else 1.0) * (0.7 if z.type == "granny" else 1.0) * (0.5 if z.slow > 0 else 1.0)
		z.spd = minf(top, z.spd + top / 0.7 * dt)
		chase(z, dt)
		if MooSim.dist(z, sim.player) < 34 and z.bite <= 0.0:
			z.state = "windup"; z.st = 0.55; z.spd = 0.0
		if z.type == "influencer" and MooSim.dist(z, sim.player) < 260:
			z.infl_t -= dt
			if z.infl_t <= 0.0:
				z.infl_t = 4.0
				sim.events.append({"kind":"camera_flash", "duration":0.25})
				sim.say(z, "Like and subscribe!", 1.4)
	path_cursor = (path_cursor + 1) % maxi(1, sim.zombies.size())

func hit_zombie(z, damage: float, item: String = "") -> void:
	if z not in sim.zombies or damage <= 0.0: return
	z.hp -= damage * (3 if z.type == "lactose" and item in ["milk", "cheese"] else 1)
	z.slow = 0.45; z.state = "chase"; z.spd = 0.0
	var direction := Vector2(z.x - sim.player.x, z.y - sim.player.y).normalized()
	z.kbx = direction.x * 210; z.kby = direction.y * 210; z.kbt = 0.16
	if z.hp > 0: return
	if z.type == "gary": finish_gary(z, false); return
	var source = sim.mods.filter(func(m): return m.key == z.src)
	if not source.is_empty():
		var reward: int = z.want * source[0].price * (3 if sim.is_boss_night() else 2)
		sim.payInto(source[0], reward, z.x, z.y - 30)
	wake(z)
	sim.zombies.erase(z)
	sim.events.append({"kind":"zombie_cured", "id":z.id})

func finish_gary(z, tripped: bool) -> void:
	sim.S.tut.gary = 2
	for i in 18:
		var angle := random.randf() * TAU
		sim.sparks.append({"x":z.x, "y":z.y - 30, "vx":cos(angle)*150, "vy":sin(angle)*150-120, "t":0.0, "col":"#e9c46a"})
	sim.zombies.erase(z)
	sim.toast("Gary tripped. Close enough." if tripped else "Gary's fine. He's straw.", 3.0)
	sim.events.append({"kind":"gary_finished", "tripped":tripped})

func wake(z) -> void:
	# Cured traffic rejoins sidewalks, including zombies standing inside crop beds.
	var free := sim.nearest_free(sim.nav_gx(z.x),sim.nav_gy(z.y),true)
	var start := Vector2(sim.nav_cx(free.x),sim.nav_cy(free.y))
	var counter = sim.mods.filter(func(m): return m.key == z.src)
	var exit := free_point(z.x + 80, z.y)
	if not counter.is_empty(): exit = Vector2(counter[0].ox - 8, counter[0].oy + 330)
	var public_exit := sim.nearest_free(sim.nav_gx(exit.x),sim.nav_gy(exit.y),true)
	exit = Vector2(sim.nav_cx(public_exit.x),sim.nav_cy(public_exit.y))
	var c := {"x":start.x, "y":start.y, "shirt":z.shirt, "pants":z.pants, "hair":z.hair, "hat":z.hat,
		"skin":z.human_skin, "face":z.face, "walk":0.0, "moving":false, "speed":90.0, "got":0, "item":z.item,
		"happy":0.0, "wait":0.0, "patience":MooSim.PATIENCE, "path":null, "pathKey":"", "say":null,
		"leave":{"x":exit.x,"y":exit.y}}
	sim.say(c, MORNING_LINES[random.randi() % MORNING_LINES.size()], 2.0)
	sim.leaving.append(c)

func end_night() -> void:
	for z in sim.zombies:
		if z.type != "gary": wake(z)
	sim.zombies = sim.zombies.filter(func(z): return z.type == "gary")
	beat = -1; elapsed = 0.0

func night_snapshot() -> Dictionary:
	var actors := []
	for z in sim.zombies:
		var actor: Dictionary = z.duplicate(true)
		actors.append(actor)
	return {"beat":beat, "elapsed":elapsed, "serial":serial, "rng":str(random.state), "cursor":path_cursor, "actors":actors}

func restore_night(d: Dictionary) -> void:
	var tut = d.get("tut", {"gary":2 if sim.S.day > 1 or sim.S.ch > 0 or int(d.get("gun",0)) > 0 else 0})
	sim.S.tut = tut.duplicate(true) if tut is Dictionary else {"gary":0}
	sim.S.tut.gary = clampi(int(sim.S.tut.get("gary",0)),0,2)
	var saved = d.get("night")
	if saved is not Dictionary:
		# Existing mid-night saves join the next beat; no retroactive spawn burst.
		elapsed = (sim.S.time - 0.7) * 300.0 if real_night() else 0.0
		beat = mini(2, int(elapsed / 30)) if real_night() else -1
		return
	elapsed = clampf(float(saved.get("elapsed",0)),0,90)
	beat = clampi(int(saved.get("beat",-1)),-1,2)
	serial = maxi(0,int(saved.get("serial",0)))
	path_cursor = maxi(0,int(saved.get("cursor",0)))
	if saved.get("rng") is String: random.state = int(saved.rng)
	for actor in saved.get("actors",[]):
		if actor is not Dictionary or actor.get("type", "") not in TYPES + ["gary"]: continue
		if sim.zombies.size() >= CAP: break
		if actor.type != "gary" and not real_night(): continue
		if actor.type == "gary" and sim.S.tut.gary != 1: continue
		var source = sim.mods.filter(func(m): return m.key == actor.get("src", ""))
		var z := new_zombie(float(actor.get("x",sim.player.x)),float(actor.get("y",sim.player.y)),actor.type,bool(actor.get("big",false)),source[0] if not source.is_empty() else null,int(actor.get("want",3)))
		z.merge(actor,true)
		unstick(z)
		sim.zombies.append(z)
	# Constructors used to fill defaults must not advance the persisted threat stream.
	serial = int(saved.get("serial",0))
	if saved.get("rng") is String: random.state = int(saved.rng)

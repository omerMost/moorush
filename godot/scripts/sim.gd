class_name MooSim
extends RefCounted
## Simulation facade and tick order, ported from prototype/index.html (frozen spec).
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
var zombies: Array = []
var night_rng := RandomNumberGenerator.new()
var night_state := {"serial":0, "beat":-1, "elapsed":0.0, "cursor":0}
var flyers: Array = []
var transfer_serial := 0
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
var NAV := {"s": 20, "ox": 0.0, "oy": 0.0, "nx": 0, "ny": 0, "blk": PackedByteArray(), "public_blk": PackedByteArray()}
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
var g_mode = null

# System seams: future zombies/combat/hearts/bosses/robbers follow this pattern.
var _zombies = preload("res://scripts/sim/zombies.gd").new(self)
var _clock = preload("res://scripts/sim/clock.gd").new(self)
var _world = preload("res://scripts/sim/world.gd").new(self)
var _items = preload("res://scripts/sim/items.gd").new(self)
var _customers = preload("res://scripts/sim/customers.gd").new(self)
var _agents = preload("res://scripts/sim/agents.gd").new(self)
var _nav = preload("res://scripts/sim/nav.gd").new(self)
var _saves = preload("res://scripts/sim/saves.gd").new(self)
var _feedback = preload("res://scripts/sim/feedback.gd").new(self)


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


func update(dt: float) -> void:
	T += dt
	upd_clock(dt)
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
		if walk_to(c, c.leave.x, c.leave.y, c.speed, dt, true):
			leaving.remove_at(i)
	for h in helpers:
		upd_helper(h, dt)
	upd_zombies(dt)
	upd_ground(dt)
	upd_speech(dt)
	for i in range(flyers.size() - 1, -1, -1):
		var f = flyers[i]
		f.t += dt
		if f.t >= f.dur:
			if f.dest != null:
				f.dest.inc -= 1
				if f.has("slot"): f.dest.arriving_slots.erase(f.slot)
				if f.has("stack_token"): f.dest.pending_ids.erase(f.stack_token)
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


# Release in-flight callbacks that capture this simulation before discarding it.
func dispose() -> void:
	flyers.clear()


# Source-compatible forwarding API; default arguments and static calls stay intact.
func mod_by(id: String, district: int = -1): return _world.mod_by(id, district)
func active(m) -> bool: return _world.active(m)
func live() -> Array: return _world.live()
func build_module(cfg: Dictionary, d: int) -> Dictionary: return _world.build_module(cfg, d)
func new_animal(a0) -> Dictionary: return _world.new_animal(a0)
func sync_units(m) -> void: _world.sync_units(m)
func make_belt(m): return _world.make_belt(m)
static func belt_room(b) -> bool: return preload("res://scripts/sim/world.gd").belt_room(b)
func belt_push(b, from_x: float, from_y: float) -> void: _world.belt_push(b, from_x, from_y)
func upd_belt(b, dt: float) -> void: _world.upd_belt(b, dt)
func mk_helper(src, dst, i: int, belt) -> Dictionary: return _world.mk_helper(src, dst, i, belt)
func pad_rect(p) -> Dictionary: return _world.pad_rect(p)
func build_world() -> void: _world.build_world()
func apply_pad(p, from_load: bool) -> void: _world.apply_pad(p, from_load)
func visible_pads() -> Array: return _world.visible_pads()
func wallet() -> int: return _world.wallet()
func compute_reveal() -> void: _world.compute_reveal()
func pile_pos(r, i: int, type: String) -> Dictionary: return _items.pile_pos(r, i, type)
func ensure_layout(tray) -> void: _items.ensure_layout(tray)
func visible_slots(tray) -> Array: return _items.visible_slots(tray)
func reserve_slot(tray) -> int: return _items.reserve_slot(tray)
func stack_pos(e, i: int) -> Dictionary: return _items.stack_pos(e, i)
func fly(type: String, x: float, y: float, to: Callable, dest, dur: float = 0.24) -> Dictionary: return _items.fly(type, x, y, to, dest, dur)
func stack_fly(item: String, source, e) -> void: _items.stack_fly(item, source, e)
func take(src, e) -> bool: return _items.take(src, e)
func give(e, dst) -> void: _items.give(e, dst)
func harvest(tile, e, item: String) -> void: _items.harvest(tile, e, item)
func give_belt(e, b) -> void: _items.give_belt(e, b)
func flight_pose(f) -> Dictionary: return _items.flight_pose(f)
func move_to(e, tx: float, ty: float, sp: float, dt: float) -> bool: return _items.move_to(e, tx, ty, sp, dt)
func act() -> void: _items.act()
func new_cust(x: float, y: float, m) -> Dictionary: return _customers.new_cust(x, y, m)
static func q_slot(m, i: int) -> Dictionary: return preload("res://scripts/sim/customers.gd").q_slot(m, i)
static func spawn_factor(m) -> float: return preload("res://scripts/sim/customers.gd").spawn_factor(m)
func pocket_cap(m) -> float: return _customers.pocket_cap(m)
func upd_counter(m, dt: float) -> void: _customers.upd_counter(m, dt)
func customer_lost(c, m) -> void: _customers.customer_lost(c, m)
func on_served(m, c, amount: int) -> void: _customers.on_served(m, c, amount)
func payInto(m, amount: int, fx: float, fy: float) -> void: _customers.payInto(m, amount, fx, fy)
func upd_machine(m, dt: float) -> void: _agents.upd_machine(m, dt)
func upd_helper(h, dt: float) -> void: _agents.upd_helper(h, dt)
func nearest_ripe(item: String, list: Array): return _agents.nearest_ripe(item, list)
func tray_source(item: String, list: Array, mn: int = 1): return _agents.tray_source(item, list, mn)
func any_source(item: String, list: Array): return _agents.any_source(item, list)
func dests_for(item: String, list: Array, need_room: bool) -> Array: return _agents.dests_for(item, list, need_room)
func nearest(list: Array): return _agents.nearest(list)
func guide_target(): return _agents.guide_target()
func guide_raw(): return _agents.guide_raw()
func make_decor(c) -> void: _nav.make_decor(c)
func cell_obstacles(c) -> Array: return _nav.cell_obstacles(c)
func refresh_obstacles() -> void: _nav.refresh_obstacles()
func near_obs(x: float, y: float, R: float) -> Array: return _nav.near_obs(x, y, R)
func push_out(e, o, R: float) -> void: _nav.push_out(e, o, R)
func blocked_at(x: float, y: float, R: float = 12.0) -> bool: return _nav.blocked_at(x, y, R)
func push_out_fog(e, r) -> void: _nav.push_out_fog(e, r)
func in_bounds(e) -> bool: return _nav.in_bounds(e)
func collide_player(p) -> void: _nav.collide_player(p)
func walkable(x: float, y: float) -> bool: return _nav.walkable(x, y)
func nav_gx(x: float) -> int: return _nav.nav_gx(x)
func nav_gy(y: float) -> int: return _nav.nav_gy(y)
func nav_cx(gx: int) -> float: return _nav.nav_cx(gx)
func nav_cy(gy: int) -> float: return _nav.nav_cy(gy)
func build_nav() -> void: _nav.build_nav()
func public_blocked(x: float, y: float) -> int: return _nav.public_blocked(x, y)
func nav_blocked(gx: int, gy: int) -> int: return _nav.nav_blocked(gx, gy)
func nav_free(gx: int, gy: int, avoid_fields: bool = false) -> bool: return _nav.nav_free(gx, gy, avoid_fields)
func nearest_free(gx: int, gy: int, avoid_fields: bool = false) -> Vector2i: return _nav.nearest_free(gx, gy, avoid_fields)
func line_free(ax: float, ay: float, bx: float, by: float, avoid_fields: bool = false) -> bool: return _nav.line_free(ax, ay, bx, by, avoid_fields)
func find_path(ax: float, ay: float, bx: float, by: float, avoid_fields: bool = false): return _nav.find_path(ax, ay, bx, by, avoid_fields)
static func _hpush(heap: Array, i: int, f: float) -> void: preload("res://scripts/sim/nav.gd")._hpush(heap, i, f)
static func _hpop(heap: Array) -> Array: return preload("res://scripts/sim/nav.gd")._hpop(heap)
func walk_to(h, tx: float, ty: float, sp: float, dt: float, avoid_fields: bool = false) -> bool: return _nav.walk_to(h, tx, ty, sp, dt, avoid_fields)
func snapshot() -> Dictionary: return _saves.snapshot()
func fresh_state() -> void: _saves.fresh_state()
func apply_state(d: Dictionary) -> void: _saves.apply_state(d)
func travel_to(district: int) -> bool: return _saves.travel_to(district)
func slot_path(i: int) -> String: return _saves.slot_path(i)
func read_slot(i: int): return _saves.read_slot(i)
func write_slot(i: int, d: Dictionary) -> void: _saves.write_slot(i, d)
func delete_slot(i: int) -> void: _saves.delete_slot(i)
func save(important: bool) -> void: _saves.save(important)
func start_slot(i: int) -> bool: return _saves.start_slot(i)
func pad_named(name: String): return _saves.pad_named(name)
func state_summary() -> Dictionary: return _saves.state_summary()
func toast(t: String, dur: float = 2.2) -> void: _feedback.toast(t, dur)
func warn(t: String) -> void: _feedback.warn(t)
func burst(c, n: int = 28) -> void: _feedback.burst(c, n)
func say(e, text: String, dur: float = 1.8) -> void: _feedback.say(e, text, dur)
static func icon(t: String) -> String: return preload("res://scripts/sim/feedback.gd").icon(t)
func upd_ground(dt: float) -> void: _feedback.upd_ground(dt)
func upd_speech(dt: float) -> void: _feedback.upd_speech(dt)

# Clock transitions dispatch through the facade for later checkpoint/threat hooks.
func reset_clock() -> void: _clock.reset_clock()
func restore_clock(d: Dictionary) -> void: _clock.restore_clock(d)
func phase_idx() -> int: return _clock.phase_idx()
func is_night() -> bool: return _clock.is_night()
func is_boss_night() -> bool: return _clock.is_boss_night()
func darkness() -> float: return _clock.darkness()
func clock_label() -> String: return _clock.clock_label()
func upd_clock(dt: float) -> void: _clock.upd_clock(dt)
func on_phase(phase: int) -> void: _clock.on_phase(phase)
func sunrise() -> void: _clock.sunrise()

# Night actor seams for the upcoming combat/hearts ports.
func reset_night(chapter_entry: bool = false) -> void: _zombies.reset_night(chapter_entry)
func begin_night() -> void: _zombies.begin_night()
func advance_night(dt: float) -> void: _zombies.advance_night(dt)
func evening_gary() -> void: _zombies.evening_gary()
func real_night() -> bool: return _zombies.real_night()
func horde_zombie(): return _zombies.horde_zombie()
func turn_customer(c, m) -> bool: return _zombies.turn_customer(c, m)
func upd_zombies(dt: float) -> void: _zombies.upd_zombies(dt)
func hit_zombie(z, damage: float, item: String = "") -> void: _zombies.hit_zombie(z, damage, item)
func end_night() -> void: _zombies.end_night()
func night_snapshot() -> Dictionary: return _zombies.night_snapshot()
func restore_night(d: Dictionary) -> void: _zombies.restore_night(d)
func gary_guide(): return _zombies.gary_guide()

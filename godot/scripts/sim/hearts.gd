extends RefCounted
## Health and two immutable, slot-local rollback snapshots (ADR 0022).
const MAX_HEARTS := 5
const IMMUNITY := 1.0
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func reset_hearts() -> void:
	sim.S.hearts = MAX_HEARTS
	sim.S.stats = {}
	sim.S.hats = []
	sim.inv_t = 0.0
	sim.faint = null
	sim.checkpoints = {}

func restore_hearts(d: Dictionary) -> void:
	sim.S.hearts = clampi(int(d.get("hearts", MAX_HEARTS)), 0, MAX_HEARTS)
	sim.S.stats = d.get("stats", {}).duplicate(true) if d.get("stats") is Dictionary else {}
	sim.S.hats = d.get("hats", []).duplicate(true) if d.get("hats") is Array else []
	var immunity := float(d.get("inv_t", 0.0))
	sim.inv_t = clampf(immunity, 0.0, IMMUNITY) if is_finite(immunity) else 0.0
	sim.faint = d.get("faint").duplicate(true) if d.get("faint") is Dictionary else null
	if sim.S.hearts == 0 and sim.faint == null:
		sim.faint = {"cause":"a zombie", "checkpoint":"chapter_start"}
	sim.checkpoints = d.get("checkpoints", {}).duplicate(true) if d.get("checkpoints") is Dictionary else {}
	if d.get("rng") is String: sim.rng.state = int(d.rng)
	var cargo = d.get("helper_cargo", [])
	if cargo is Array:
		for saved in cargo:
			if not saved is Dictionary: continue
			var matches := sim.helpers.filter(func(h): return saved.get("d") == h.d and saved.get("src_id") == h.src_id and saved.get("dst_id") == h.dst_id and bool(saved.get("belt", false)) == (h.belt != null))
			if matches.is_empty(): continue
			var h = matches[0]
			for key in ["x", "y", "state", "t", "walk", "face", "stack"]:
				if saved.has(key): h[key] = saved[key].duplicate(true) if saved[key] is Dictionary else saved[key]
			h.path = null; h.pathKey = ""

	# Legacy saves acquire a baseline only after their complete migration/rebuild.
	if not sim.checkpoints.get("chapter_start") is Dictionary:
		sim.capture_checkpoint("chapter_start")
	if not d.has("checkpoints") and sim.is_night() and not sim.checkpoints.get("dusk") is Dictionary:
		sim.capture_checkpoint("dusk")

func upd_hearts(dt: float) -> void:
	sim.inv_t = maxf(0.0, sim.inv_t - dt)
	if sim.inv_t < 1e-10: sim.inv_t = 0.0

func refill_hearts() -> void:
	sim.S.hearts = MAX_HEARTS
	sim.inv_t = 0.0

func hurt_player(cause: String, damage: int = 1) -> bool:
	if damage <= 0 or sim.faint != null or sim.inv_t > 0.0: return false
	sim.S.hearts = maxi(0, sim.S.hearts - damage)
	sim.inv_t = IMMUNITY
	sim.S.stats.hits = int(sim.S.stats.get("hits", 0)) + 1
	sim.shake_amt = maxf(sim.shake_amt, 5.0)
	if sim.S.hearts == 0:
		sim.S.stats.faints = int(sim.S.stats.get("faints", 0)) + 1
		sim.faint = {"cause":cause, "checkpoint":"chapter_start" if sim.is_boss_night() else "dusk"}
		sim.move_in = Vector2.ZERO; sim.test_in = Vector2.ZERO
		sim.clear_combat_input()
		sim.save(true)
	return true

func zombie_bite(z: Dictionary) -> void:
	if z.type == "gary": return
	sim.events.append({"kind":"zombie_bite", "id":z.id, "type":z.type})
	if not sim.hurt_player("Karen" if z.type == "karen" else "a " + str(z.type) + " zombie"): return
	var st = sim.player.stack
	# Only arrived goods can be knocked off; pending transfer reservations survive.
	st.n -= mini(6 if z.type == "karen" else 3, MooSim.avail(st))
	if st.n == 0: st.type = null
	if sim.faint != null: sim.save(true)

func helper_snapshot(settle_pending: bool = false) -> Array:
	var cargo := []
	for h in sim.helpers:
		var entry := {}
		for key in ["d", "src_id", "dst_id", "state", "t", "walk", "face"]: entry[key] = h[key]
		entry.t = snappedf(h.t, 0.000001)
		entry.walk = snappedf(h.walk, 0.000001)
		entry.belt = h.belt != null
		entry.x = snappedf(h.x, 0.000001) if settle_pending else int(round(h.x))
		entry.y = snappedf(h.y, 0.000001) if settle_pending else int(round(h.y))
		var count: int = h.stack.n if settle_pending else MooSim.avail(h.stack)
		entry.stack = {"type":h.stack.type if count > 0 else null, "n":count, "inc":0}
		cargo.append(entry)
	cargo.sort_custom(func(a, b): return route_key(a) < route_key(b))
	return cargo

static func route_key(h: Dictionary) -> String:
	return "%d:%s:%s:%s" % [h.d, h.src_id, h.dst_id, h.belt]

func capture_checkpoint(kind: String) -> void:
	assert(kind in ["dusk", "chapter_start"])
	var d := sim.snapshot()
	d.erase("checkpoints"); d.erase("t"); d.erase("faint")
	# Settle pending goods once on rollback, without mutating the live transfer state.
	for m in sim.mods:
		if not d.bx.has(m.key): continue
		var o = d.bx[m.key]
		for pair in [["hopper","h"], ["tray","t"], ["box","b"], ["cash","cn"]]:
			if m.has(pair[0]): o[pair[1]] = m[pair[0]].n
		if m.has("tray"): o.tp = m.tray.item_slots.duplicate()
	var st = sim.player.stack
	d.hold = [st.type, st.n] if st.type != null else null
	d.helper_cargo = sim.helper_snapshot(true)
	sim.checkpoints[kind] = checkpoint_numbers(d)

## JSON float parsing can differ by one ULP. Frozen backup values use six decimals;
## the live clock and actor stream keep their existing full-precision save contract.
static func checkpoint_numbers(value):
	if value is float: return snappedf(value, 0.000001)
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = checkpoint_numbers(value[key])
		return result
	if value is Array: return value.map(func(v): return checkpoint_numbers(v))
	return value

func restore_checkpoint() -> bool:
	if sim.faint == null: return false
	var kind: String = sim.faint.checkpoint
	if not sim.checkpoints.get(kind) is Dictionary: kind = "chapter_start"
	if not sim.checkpoints.get(kind) is Dictionary: return false
	var d: Dictionary = sim.checkpoints[kind].duplicate(true)
	d.checkpoints = sim.checkpoints.duplicate(true)
	d.tut = sim.S.tut.duplicate(true)
	d.stats = sim.S.stats.duplicate(true)
	d.hats = sim.S.hats.duplicate(true)
	d.hearts = clampi(int(d.get("hearts", MAX_HEARTS)), 1, MAX_HEARTS)
	d.inv_t = 0.0; d.faint = null
	if kind == "chapter_start":
		d.day = 1; d.time = 0.08; d.cn = 0
		# Reset the phase, preserving the baseline's exact threat stream.
		if d.get("night") is Dictionary:
			d.night.beat = -1; d.night.elapsed = 0.0; d.night.cursor = 0
			# Keep an unfinished practice actor; completed Gary is filtered on load.
			d.night.actors = sim.zombies.filter(func(z): return z.type == "gary").duplicate(true)
			for z in d.night.actors: d.night.serial = maxi(int(d.night.serial), int(z.id))
	sim.dispose() # No abandoned flight callback may deliver into the rebuilt world.
	sim.apply_state(d)
	sim.move_in = Vector2.ZERO; sim.test_in = Vector2.ZERO
	sim.toast("Try again · " + ("chapter start" if kind == "chapter_start" else "dusk"), 2.5)
	sim.save(true)
	return true

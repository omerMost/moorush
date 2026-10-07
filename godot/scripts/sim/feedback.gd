extends RefCounted
## Feedback system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func toast(t: String, dur: float = 2.2) -> void:
	if sim.toasts.size() and sim.toasts[sim.toasts.size() - 1].text == t:
		return
	sim.toasts.append({"text": t, "t": 0.0, "dur": dur})
	if sim.toasts.size() > 2:
		sim.toasts.pop_front()

func warn(t: String) -> void:
	if sim.warn_t <= 0:
		sim.toast(t, 1.6)
		sim.warn_t = 2.5
		sim.events.append({"kind": "warn"})

func burst(c, n: int = 28) -> void:
	for i in n:
		var a := sim.rng.randf() * TAU
		var v := sim.rnd(80, 230)
		sim.sparks.append({"x": c.x, "y": c.y, "vx": cos(a) * v, "vy": sin(a) * v - 120, "t": 0.0,
			"col": sim.pick(["#ffd54a", "#7ed957", "#ffffff", "#ff9f43", "#4fc3f7"])})

func say(e, text: String, dur: float = 1.8) -> void:
	e.say = {"text": text, "t": dur}

static func icon(t: String) -> String:
	return MooData.ITEMS[t].e if MooData.ITEMS.has(t) else t

func upd_ground(dt: float) -> void:
	for i in range(sim.ground.size() - 1, -1, -1):
		var c = sim.ground[i]
		c.ft += dt
		c.t -= dt
		if c.ft > 0.35 and MooSim.dist(c, sim.player) < 34:
			sim.S.money += c.val
			sim.events.append({"kind": "coin"})
			sim.ground.remove_at(i)
			continue
		if c.t <= 0:
			sim.ground.remove_at(i)

func upd_speech(dt: float) -> void:
	var ents: Array = [sim.player]
	for m in sim.mods:
		if m.type == "counter":
			ents.append_array(m.q)
	ents.append_array(sim.leaving)
	ents.append_array(sim.zombies)
	for e in ents:
		if e.get("say") != null:
			e.say.t -= dt
			if e.say.t <= 0:
				e.say = null

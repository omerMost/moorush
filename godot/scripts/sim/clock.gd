extends RefCounted
## Chapter-local v9 clock. Transition hooks are seams for checkpoints and threats.
const DAY_LEN := 300.0
const START_TIME := 0.08
const PHASE_ENDS := [0.25, 0.5, 0.7, 1.0]
const PHASE_NAMES := ["Morning", "Midday", "Evening", "Night"]
const EPSILON := 1e-10
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func reset_clock() -> void:
	sim.S.day = 1
	sim.S.time = START_TIME
	sim.S.cn = 0
	sim.reset_night(true)

func restore_clock(d: Dictionary) -> void:
	sim.S.day = maxi(1, int(d.get("day", 1)))
	var value = d.get("time", START_TIME)
	var time := float(value) if value is int or value is float else START_TIME
	sim.S.time = clampf(time, 0.0, 1.0 - EPSILON) if is_finite(time) else START_TIME
	var inferred: int = sim.S.day - 1 + (1 if sim.is_night() else 0)
	sim.S.cn = clampi(int(d.get("cn", inferred)), 0, sim.S.day)

func phase_idx() -> int:
	for i in PHASE_ENDS.size():
		if sim.S.time < PHASE_ENDS[i]: return i
	return 3

func is_night() -> bool:
	return sim.S.time >= 0.7

func is_boss_night() -> bool:
	return sim.is_night() and sim.S.cn > 0 and sim.S.cn % 3 == 0

## Frozen prototype darkness curve, including the first 18 seconds after dawn.
func darkness() -> float:
	var t: float = sim.S.time
	if t < 0.06: return 0.55 * (1.0 - t / 0.06)
	if t < 0.55: return 0.0
	if t < 0.7: return (t - 0.55) / 0.15 * 0.3
	if t < 0.76: return 0.3 + (t - 0.7) / 0.06 * 0.3
	return 0.6

func clock_label() -> String:
	var phase := sim.phase_idx()
	if phase == 3: return "Night %d" % sim.S.cn
	return "Day %d · %s" % [sim.S.day, PHASE_NAMES[phase]]

## Consume each boundary in order even for a large explicit test tick.
## Loading a phase does not replay dusk; the next boundary fires exactly once.
func upd_clock(dt: float) -> void:
	if dt <= 0.0 or not is_finite(dt): return
	var remaining := dt / DAY_LEN
	while remaining > 0.0:
		var boundary: float = PHASE_ENDS[sim.phase_idx()]
		var step := minf(remaining, boundary - float(sim.S.time))
		if sim.is_night(): sim.advance_night(step * DAY_LEN)
		sim.S.time += step
		remaining -= step
		if sim.S.time >= boundary - EPSILON:
			sim.S.time = boundary
			if boundary == 1.0:
				sim.S.time = 0.0
				sim.sunrise()
				sim.on_phase(0)
			else:
				sim.on_phase(sim.phase_idx())

func on_phase(phase: int) -> void:
	if phase == 3:
		sim.S.cn += 1
		sim.begin_night()
		sim.toast("Night %d · Sunrise in 90 seconds" % sim.S.cn, 2.4)
	elif phase == 2:
		sim.evening_gary()
		sim.toast("Evening on the farm", 2.4)
	sim.events.append({"kind": "phase", "phase": phase, "day": sim.S.day,
		"cn": sim.S.cn, "boss_night": sim.is_boss_night()})

func sunrise() -> void:
	sim.end_night()
	sim.S.day += 1
	sim.events.append({"kind": "sunrise", "night": sim.S.cn, "day": sim.S.day})
	sim.toast("Survived night %d · Day %d" % [sim.S.cn, sim.S.day], 3.0)
	sim.save(true)

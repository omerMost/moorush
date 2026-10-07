extends RefCounted
## Saves system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

func snapshot() -> Dictionary:
	var bx := {}
	for m in sim.mods:
		var o := {}
		if m.has("hopper"): o.h = MooSim.avail(m.hopper)
		if m.has("tray"):
			o.t = MooSim.avail(m.tray)
			o.tp = sim.visible_slots(m.tray).duplicate()
		if m.has("box"): o.b = MooSim.avail(m.box)
		if m.has("cash"):
			o.cn = MooSim.avail(m.cash); o.cv = m.cash.val
		if o.size():
			bx[m.key] = o
	var bl := {}
	for b in sim.belts:
		bl[b.m.key] = b.items.size()
	var pk := {}
	for p in sim.pads:
		if p.paid > 0:
			pk[str(p.d) + ":" + p.name] = p.paid
	var rep := {}
	for m in sim.mods:
		if m.has("rep"):
			rep[m.key] = round(m.rep * 10) / 10.0
	var st = sim.player.stack
	return {"v": 1, "ver": 9, "engine": "godot", "t": int(Time.get_unix_time_from_system() * 1000), "ch": sim.S.ch, "money": sim.S.money,
		"day": sim.S.day, "time": sim.S.time, "cn": sim.S.cn,
		"tut": sim.S.tut.duplicate(true), "night": sim.night_snapshot(),
		"votes": 0, "cap": sim.S.cap, "won": false, "done": sim.S.done,
		"paid": sim.pads.map(func(p): return p.paid), "pk": pk, "bx": bx, "bl": bl,
		"px": int(round(sim.player.x)), "py": int(round(sim.player.y)), "rep": rep,
		"hold": [st.type, maxi(0, st.n - st.inc)] if st.type != null else null}

func fresh_state() -> void:
	sim.stage = MooData.stage0()
	sim.S = {"ch": 0, "money": 0, "votes": 0, "cap": 8, "won": false, "done": false}
	sim.reset_night()
	sim.reset_clock()
	sim.build_world()
	sim.T = 0.0; sim.act_t = 0.0; sim.save_t = 0.0; sim.warn_t = 0.0; sim.g_cache = null; sim.g_mode = null
	sim.toasts = []; sim.events = []; sim.cam_focus = null
	sim.compute_reveal()
	sim.bounds = sim.target_bounds.duplicate()
	for c in sim.cells:
		c.fog = 0.0 if c.on else 1.0

func apply_state(d: Dictionary) -> void:
	sim.fresh_state()
	sim.S.ch = clampi(int(d.get("ch", 0)), 0, MooData.STAGE_COUNT - 1)
	sim.stage = MooData.stage_at(sim.S.ch)
	sim.S.money = int(d.get("money", 0))
	sim.S.cap = maxi(int(d.get("cap", 8)), 8)
	sim.S.done = false
	var paid = d.get("paid")
	if int(d.get("ver", 0)) >= 9 and paid is Array and paid.size() == sim.pads.size():
		for i in sim.pads.size():
			sim.pads[i].paid = mini(int(paid[i]), sim.pads[i].cost)
	elif d.get("pk") is Dictionary:
		# keyed by name: a reordered pad list keeps finished upgrades finished
		for p in sim.pads:
			var v = d.pk.get(str(p.d) + ":" + p.name)
			if v != null:
				if int(d.get("ver", 0)) >= 9:
					p.paid = clampi(int(v), 0, p.cost)
				else:
					p.paid = p.cost if int(v) >= p.cost * 0.9 else mini(p.cost - 1, int(v))
	elif paid is Array:
		# Array-only native saves used the implemented chapter count at the time.
		var count := 0
		for chapter in range(MooData.STAGE_COUNT):
			count += MooData.stage_at(chapter).pads.size()
			if paid.size() == count:
				for i in paid.size(): sim.pads[i].paid = clampi(int(paid[i]), 0, sim.pads[i].cost)
				break
	# Previous slice endpoints become ownership of their newly available district.
	var saved_chapter := int(d.get("ch", 0))
	if bool(d.get("done", false)) and saved_chapter >= 0 and saved_chapter < MooData.STAGE_COUNT - 1:
		for p in sim.pads:
			if p.d == saved_chapter and p.fx == "gate": p.paid = p.cost
	for p in sim.pads:
		if p.paid >= p.cost:
			sim.apply_pad(p, true)
	sim.S.done = sim.S.ch == MooData.STAGE_COUNT - 1 and (bool(d.get("done", false)) and saved_chapter == MooData.STAGE_COUNT - 1 or sim.pads.any(func(p): return p.d == MooData.STAGE_COUNT - 1 and p.fx == "gate" and p.paid >= p.cost))
	sim.stage = MooData.stage_at(sim.S.ch)
	sim.restore_clock(d)
	var bx = d.get("bx", {})
	for m in sim.mods:
		var o = bx.get(m.key)
		if o == null:
			continue
		if m.has("hopper") and o.has("h"): m.hopper.n = clampi(int(o.h), 0, m.hopper.cap)
		if m.has("tray") and o.has("t"):
			m.tray.n = clampi(int(o.t), 0, m.tray.cap)
			var positions: Array = o.get("tp", [])
			var restored: Array = []
			for value in positions:
				var slot := int(value)
				if slot < 0 or slot >= m.tray.cap or slot in restored: break
				restored.append(slot)
			m.tray.item_slots = restored if restored.size() == m.tray.n else range(m.tray.n)
			m.tray.arriving_slots = []
		if m.has("box") and o.has("b"): m.box.n = clampi(int(o.b), 0, m.box.cap)
		if m.has("cash") and o.has("cn"):
			m.cash.n = maxi(0, int(o.cn)); m.cash.val = maxi(0, int(o.cv))
	var bl = d.get("bl", {})
	for b in sim.belts:
		var n := int(bl.get(b.m.key, 0))
		for i in n:
			b.items.append(maxf(0.0, b.len - i * b.gap))
	if d.get("px") != null:
		sim.player.x = float(d.px); sim.player.y = float(d.py)
	var hold = d.get("hold")
	if hold is Array and MooData.ITEMS.has(str(hold[0])):
		sim.player.stack = {"type": str(hold[0]), "n": mini(int(hold[1]), sim.S.cap), "inc": 0}
		if sim.player.stack.n <= 0:
			sim.player.stack.type = null
	var rep = d.get("rep", {})
	for m in sim.mods:
		if rep.has(m.key):
			m.rep = float(rep[m.key])
	sim.compute_reveal()
	sim.bounds = sim.target_bounds.duplicate()
	for c in sim.cells:
		c.fog = 0.0 if c.on else 1.0
	if sim.blocked_at(sim.player.x, sim.player.y, 6):
		var f := sim.nearest_free(sim.nav_gx(sim.player.x), sim.nav_gy(sim.player.y))
		sim.player.x = sim.nav_cx(f.x); sim.player.y = sim.nav_cy(f.y)

	sim.restore_night(d)

func travel_to(district: int) -> bool:
	if district < 0 or district > sim.S.ch or district >= MooData.STAGE_COUNT: return false
	var a = sim.mod_by("A", district)
	sim.player.x = a.rect.x + a.rect.w / 2
	sim.player.y = a.rect.y + a.rect.h + 30
	sim.player.pinned = 0.0
	sim.move_in = Vector2.ZERO; sim.test_in = Vector2.ZERO
	sim.g_cache = null; sim.g_mode = null; sim.cam_focus = null
	sim.bounds = sim.target_bounds.duplicate()
	return true

func slot_path(i: int) -> String:
	return sim.save_dir.path_join("moo-rush-slot-%d.json" % i)

func read_slot(i: int):
	if not FileAccess.file_exists(sim.slot_path(i)):
		return null
	var txt := FileAccess.get_file_as_string(sim.slot_path(i))
	var d = JSON.parse_string(txt)
	return d if d is Dictionary else null

func write_slot(i: int, d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(sim.save_dir)
	var f := FileAccess.open(sim.slot_path(i), FileAccess.WRITE)
	if f:
		# Preserve fractional clock values exactly across disk round-trips.
		f.store_string(JSON.stringify(d, "", true, true))
		f.close()

func delete_slot(i: int) -> void:
	if FileAccess.file_exists(sim.slot_path(i)):
		DirAccess.remove_absolute(sim.slot_path(i))
	if i == sim.cur_slot:
		sim.cur_slot = 0
		sim.fresh_state()

func save(important: bool) -> void:
	if sim.cur_slot == 0 or not sim.autosave:
		return
	sim.write_slot(sim.cur_slot, sim.snapshot())
	if important:
		sim.saved_flash = 1.4

## startSlot (L2096): load the slot, or start fresh in it.
func start_slot(i: int) -> bool:
	sim.cur_slot = i
	var d = sim.read_slot(i)
	if d != null:
		sim.apply_state(d)
		sim.toast("Slot %d loaded — welcome back!" % i, 2.2)
		return true
	sim.fresh_state()
	sim.save(true)
	return false

func pad_named(name: String):
	for p in sim.pads:
		if p.name == name:
			return p
	return null

func state_summary() -> Dictionary:
	var out := {"t": sim.T, "money": sim.S.money, "cap": sim.S.cap, "done": sim.S.done, "x": sim.player.x, "y": sim.player.y,
		"stack": [sim.player.stack.type, sim.player.stack.n], "pads": {}, "helpers": sim.helpers.size()}
	for p in sim.pads:
		out.pads[p.name] = [p.paid, p.cost]
	return out

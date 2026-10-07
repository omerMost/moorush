extends RefCounted
## Nav system. State and public entry points remain on MooSim (ADR 0019).
## Weak ownership prevents a RefCounted cycle; callbacks retain their existing lifetime.
var _owner: WeakRef
var sim: MooSim:
	get: return _owner.get_ref()

func _init(owner: MooSim) -> void:
	_owner = weakref(owner)

## Frozen HTML makeDecor: stable scenery, with the walking lane kept clear.
func make_decor(c) -> void:
	var seed_value: int = c.seed
	c.decor = []
	if MooSim.hash01(seed_value + 99) > 0.45:
		c.decor.append({"kind":"pond", "x":c.x + MooSim.CW / 2 + (MooSim.hash01(seed_value + 5) - 0.5) * 80, "y":c.y + 175, "rx":78.0, "ry":44.0})
	var tries := 0
	var trees := 0
	while trees < 9 and tries < 80:
		tries += 1
		var radius := 20 + MooSim.hash01(seed_value + tries * 13) * 16
		var x: float = c.x + 45 + radius + MooSim.hash01(seed_value + tries) * (MooSim.CW - 90 - 2 * radius)
		var y: float = c.y + 45 + radius + MooSim.hash01(seed_value + tries * 7 + 3) * (MooSim.CHh - 90 - 2 * radius)
		if y + radius > c.y + 275 and y - radius < c.y + 385: continue
		var overlaps := false
		for d in c.decor:
			if d.kind == "tree":
				overlaps = overlaps or Vector2(d.x - x, d.y - y).length() < d.r + radius + 26
			else:
				overlaps = overlaps or (absf(d.x - x) < d.rx + radius + 20 and absf(d.y - y) < d.ry + radius + 20)
		if overlaps: continue
		c.decor.append({"kind":"tree", "x":x, "y":y, "r":radius})
		trees += 1

func cell_obstacles(c) -> Array:
	var o := []
	if not c.on:
		o.append({"r": {"x": c.x, "y": c.y, "w": c.w, "h": c.h}, "fog": true})
		return o
	var m = c.mod
	if m != null:
		if m.type == "garage":
			o.append({"r": m.shop})
		if not sim.active(m):
			return o
		if m.type == "machine":
			o.append({"r": m.pen})
		if m.type == "counter":
			o.append({"r": m.bench})
		if m.has("bin"):
			o.append({"r": m.bin})
	else:
		for d in c.decor:
			if d.kind == "tree": o.append({"c":{"x":d.x,"y":d.y,"r":d.r * 0.8}})
			else: o.append({"r":{"x":d.x-d.rx+10,"y":d.y-d.ry+8,"w":d.rx*2-20,"h":d.ry*2-16}})
	return o

func refresh_obstacles() -> void:
	var changed: Array = []
	for c in sim.cells:
		var obstacles := sim.cell_obstacles(c)
		if c.obs != obstacles:
			c.obs = obstacles
			changed.append(c)
	if sim.NAV.blk.size() != sim.NAV.nx * sim.NAV.ny:
		sim.build_nav()
	elif changed.is_empty():
		return
	else:
		# Fog/walkable margins and collision radii extend beyond the cell edges.
		for c in changed:
			for gy in range(maxi(0, sim.nav_gy(c.y - 60)), mini(sim.NAV.ny, sim.nav_gy(c.y + c.h + 60) + 1)):
				for gx in range(maxi(0, sim.nav_gx(c.x - 60)), mini(sim.NAV.nx, sim.nav_gx(c.x + c.w + 60) + 1)):
					sim.NAV.blk[gy * sim.NAV.nx + gx] = sim.nav_blocked(gx, gy)
					sim.NAV.public_blk[gy * sim.NAV.nx + gx] = sim.public_blocked(sim.nav_cx(gx), sim.nav_cy(gy))
	for h in sim.helpers:
		h.path = null
	for m in sim.mods:
		if m.type == "counter":
			for customer in m.q: customer.path = null
	for customer in sim.leaving: customer.path = null

func near_obs(x: float, y: float, R: float) -> Array:
	var out := []
	for c in sim.cells:
		if x < c.x - R or x > c.x + c.w + R or y < c.y - R or y > c.y + c.h + R:
			continue
		out.append_array(c.obs)
	return out

func push_out(e, o, R: float) -> void:
	if o.has("c"):
		var circle = o.c
		var offset := Vector2(e.x - circle.x, e.y - circle.y)
		var radius: float = circle.r + R
		if offset.length() < radius:
			var direction := offset.normalized() if offset.length() > 0 else Vector2.RIGHT
			e.x = circle.x + direction.x * radius
			e.y = circle.y + direction.y * radius
		return
	var r = o.r
	var cx := clampf(e.x, r.x, r.x + r.w)
	var cy := clampf(e.y, r.y, r.y + r.h)
	var dx: float = e.x - cx
	var dy: float = e.y - cy
	var d := sqrt(dx * dx + dy * dy)
	if d >= R:
		return
	if d == 0:
		var l: float = e.x - r.x
		var rt: float = r.x + r.w - e.x
		var t: float = e.y - r.y
		var b: float = r.y + r.h - e.y
		var mm := minf(minf(l, rt), minf(t, b))
		if mm == l: e.x = r.x - R
		elif mm == rt: e.x = r.x + r.w + R
		elif mm == t: e.y = r.y - R
		else: e.y = r.y + r.h + R
	else:
		e.x = cx + dx / d * R
		e.y = cy + dy / d * R

func blocked_at(x: float, y: float, R: float = 12.0) -> bool:
	for o in sim.near_obs(x, y, 60):
		if o.has("c"):
			if Vector2(x - o.c.x, y - o.c.y).length() < o.c.r + R: return true
			continue
		var r = o.r
		var cx := clampf(x, r.x, r.x + r.w)
		var cy := clampf(y, r.y, r.y + r.h)
		if Vector2(x - cx, y - cy).length() < R:
			return true
	return false

## clouds: push out toward an edge that stays inside the open world (L895)
func push_out_fog(e, r) -> void:
	var R := 12.0
	var cx := clampf(e.x, r.x, r.x + r.w)
	var cy := clampf(e.y, r.y, r.y + r.h)
	var dx: float = e.x - cx
	var dy: float = e.y - cy
	var d := sqrt(dx * dx + dy * dy)
	if d >= R:
		return
	if d > 0:
		e.x = cx + dx / d * R
		e.y = cy + dy / d * R
		if sim.in_bounds(e):
			return
	var B = sim.bounds if sim.bounds != null else sim.target_bounds
	var opts := [{"x": r.x - R, "y": e.y}, {"x": r.x + r.w + R, "y": e.y}, {"x": e.x, "y": r.y - R}, {"x": e.x, "y": r.y + r.h + R}].filter(
		func(o): return o.x >= B.x0 + 14 and o.x <= B.x1 - 14 and o.y >= B.y0 + 30 and o.y <= B.y1 - 10)
	if opts.is_empty():
		return
	var best = opts[0]
	for o in opts:
		if MooSim.dist(o, e) < MooSim.dist(best, e):
			best = o
	e.x = best.x
	e.y = best.y

func in_bounds(e) -> bool:
	var B = sim.bounds if sim.bounds != null else sim.target_bounds
	return e.x >= B.x0 + 14 and e.x <= B.x1 - 14 and e.y >= B.y0 + 30 and e.y <= B.y1 - 10

func collide_player(p) -> void:
	var obs := sim.near_obs(p.x, p.y, 80)
	for k in 3:
		for o in obs:
			if o.get("fog", false):
				sim.push_out_fog(p, o.r)
			else:
				sim.push_out(p, o, 12)

## the open world = revealed cells; you can never walk into the clouds (L940)
func walkable(x: float, y: float) -> bool:
	var near := false
	for c in sim.cells:
		if x < c.x - 50 or x > c.x + c.w + 50 or y < c.y - 50 or y > c.y + c.h + 50:
			continue
		var inside: bool = x >= c.x and x < c.x + c.w and y >= c.y and y < c.y + c.h
		if not c.on and inside:
			return false
		if c.on:
			near = true
	return near

# navigation grid + A* (L911-937)
func nav_gx(x: float) -> int: return int(floor((x - sim.NAV.ox) / sim.NAV.s))
func nav_gy(y: float) -> int: return int(floor((y - sim.NAV.oy) / sim.NAV.s))
func nav_cx(gx: int) -> float: return sim.NAV.ox + gx * sim.NAV.s + sim.NAV.s / 2.0
func nav_cy(gy: int) -> float: return sim.NAV.oy + gy * sim.NAV.s + sim.NAV.s / 2.0

func build_nav() -> void:
	var blk := PackedByteArray()
	blk.resize(sim.NAV.nx * sim.NAV.ny)
	for gy in sim.NAV.ny:
		for gx in sim.NAV.nx:
			blk[gy * sim.NAV.nx + gx] = sim.nav_blocked(gx, gy)
	sim.NAV.blk = blk
	var public_mask := PackedByteArray()
	public_mask.resize(sim.NAV.nx * sim.NAV.ny)
	for gy in sim.NAV.ny:
		for gx in sim.NAV.nx:
			public_mask[gy * sim.NAV.nx + gx] = sim.public_blocked(sim.nav_cx(gx), sim.nav_cy(gy))
	sim.NAV.public_blk = public_mask

## Public foot traffic avoids crop beds and item holders; harvesting/pickup keep the normal mask.
func public_blocked(x: float, y: float) -> int:
	var point := {"x":x,"y":y}
	for m in sim.mods:
		if not sim.active(m): continue
		if m.type == "field" and MooSim.in_r(point, m.rect, 18): return 1
		if m.has("tray") and MooSim.in_r(point, m.tray.rect, 25): return 1
	return 0

func nav_blocked(gx: int, gy: int) -> int:
	var x := sim.nav_cx(gx)
	var y := sim.nav_cy(gy)
	return 1 if not sim.walkable(x, y) or sim.blocked_at(x, y, 14) else 0

func nav_free(gx: int, gy: int, avoid_fields: bool = false) -> bool:
	return gx >= 0 and gy >= 0 and gx < sim.NAV.nx and gy < sim.NAV.ny and sim.NAV.blk[gy * sim.NAV.nx + gx] == 0 and (not avoid_fields or sim.NAV.public_blk[gy * sim.NAV.nx + gx] == 0)

func nearest_free(gx: int, gy: int, avoid_fields: bool = false) -> Vector2i:
	if sim.nav_free(gx, gy, avoid_fields):
		return Vector2i(gx, gy)
	for r in range(1, 25):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) == r and sim.nav_free(gx + dx, gy + dy, avoid_fields):
					return Vector2i(gx + dx, gy + dy)
	return Vector2i(gx, gy)

func line_free(ax: float, ay: float, bx: float, by: float, avoid_fields: bool = false) -> bool:
	var d := Vector2(bx - ax, by - ay).length()
	var n := int(ceil(d / 8))
	for i in range(1, n):
		var x := ax + (bx - ax) * i / n
		var y := ay + (by - ay) * i / n
		if not sim.nav_free(sim.nav_gx(x), sim.nav_gy(y), avoid_fields):
			return false
	return true

func find_path(ax: float, ay: float, bx: float, by: float, avoid_fields: bool = false):
	var nx: int = sim.NAV.nx
	if avoid_fields and not sim.nav_free(sim.nav_gx(bx), sim.nav_gy(by), true): return null
	if sim.line_free(ax, ay, bx, by, avoid_fields):
		return [{"x": bx, "y": by}]
	var s0 := sim.nearest_free(sim.nav_gx(ax), sim.nav_gy(ay), avoid_fields)
	var t0 := sim.nearest_free(sim.nav_gx(bx), sim.nav_gy(by), avoid_fields)
	var N: int = nx * sim.NAV.ny
	var g := PackedFloat32Array(); g.resize(N); g.fill(1e9)
	var from := PackedInt32Array(); from.resize(N); from.fill(-1)
	var closed := PackedByteArray(); closed.resize(N)
	var heap: Array = []
	var hfn := func(x: int, y: int) -> float:
		var dx := absi(x - t0.x); var dy := absi(y - t0.y)
		return dx + dy - 0.59 * mini(dx, dy)
	var si := s0.y * nx + s0.x
	var ti := t0.y * nx + t0.x
	g[si] = 0
	_hpush(heap, si, hfn.call(s0.x, s0.y))
	var it := 0
	while heap.size() and it < 60000:
		it += 1
		var i: int = _hpop(heap)[1]
		if closed[i]:
			continue
		closed[i] = 1
		if i == ti:
			break
		var x := i % nx
		var y := i / nx
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var X: int = x + dx
				var Y: int = y + dy
				if not sim.nav_free(X, Y, avoid_fields):
					continue
				if dx != 0 and dy != 0 and (not sim.nav_free(x + dx, y, avoid_fields) or not sim.nav_free(x, y + dy, avoid_fields)):
					continue
				var j := Y * nx + X
				var ng := g[i] + (1.41 if dx != 0 and dy != 0 else 1.0)
				if ng < g[j]:
					g[j] = ng
					from[j] = i
					_hpush(heap, j, ng + hfn.call(X, Y))
	if from[ti] < 0 and ti != si:
		return null
	var pts := []
	var k := ti
	while k != si and k >= 0:
		pts.append({"x": sim.nav_cx(k % nx), "y": sim.nav_cy(k / nx)})
		k = from[k]
	pts.reverse()
	pts.append({"x": bx, "y": by})
	# smooth: skip waypoints we can see past
	var out := []
	var cx := ax; var cy := ay; var q := 0
	while q < pts.size():
		var j := pts.size() - 1
		while j > q and not sim.line_free(cx, cy, pts[j].x, pts[j].y, avoid_fields):
			j -= 1
		out.append(pts[j])
		cx = pts[j].x; cy = pts[j].y
		q = j + 1
	return out

static func _hpush(heap: Array, i: int, f: float) -> void:
	heap.append([f, i])
	var k := heap.size() - 1
	while k > 0:
		var p := (k - 1) >> 1
		if heap[p][0] <= heap[k][0]:
			break
		var tmp = heap[p]; heap[p] = heap[k]; heap[k] = tmp
		k = p

static func _hpop(heap: Array) -> Array:
	var top = heap[0]
	var last = heap.pop_back()
	if heap.size():
		heap[0] = last
		var k := 0
		while true:
			var l := 2 * k + 1
			var r := l + 1
			var m := k
			if l < heap.size() and heap[l][0] < heap[m][0]: m = l
			if r < heap.size() and heap[r][0] < heap[m][0]: m = r
			if m == k:
				break
			var tmp = heap[m]; heap[m] = heap[k]; heap[k] = tmp
			k = m
	return top

func walk_to(h, tx: float, ty: float, sp: float, dt: float, avoid_fields: bool = false) -> bool:
	var key := str(round(tx)) + "," + str(round(ty))
	if h.pathKey != key or h.path == null:
		var pth = sim.find_path(h.x, h.y, tx, ty, avoid_fields)
		if pth == null and avoid_fields:
			h.path = []
			h.pathKey = key
			h.moving = false
			return false
		h.path = pth if pth != null else [{"x": tx, "y": ty}]
		h.pathKey = key
	if h.path.is_empty():
		h.moving = false
		return false
	while h.path.size() > 1 and Vector2(h.path[0].x - h.x, h.path[0].y - h.y).length() < 4:
		h.path.pop_front()
	var wp = h.path[0]
	var arrived := sim.move_to(h, wp.x, wp.y, sp, dt)
	return h.path.size() == 1 and arrived

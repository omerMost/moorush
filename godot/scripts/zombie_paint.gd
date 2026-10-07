extends RefCounted
## Procedural grumpy faces and phone-sized props (characters.md §5–6).
static func draw_actor(ci: CanvasItem, z, time: float) -> void:
	var scale := 1.35 if z.big else 1.0
	ci.draw_set_transform(Vector2(z.x, z.y), 0.0, Vector2(scale, scale))
	var o: Dictionary = z.duplicate()
	o.walk = z.walk * 0.6
	o.bun = z.type == "granny"
	match z.type:
		"karen": o.shirt = "#8e44ad"; o.hair = "#e8c050"
		"lactose": o.shirt = "#f4f1e6"
		"vault": o.shirt = "#f28c28"
		"influencer": o.shirt = "#ff5ea8"
		"flag": o.shirt = "#5b4636"
		"granny": o.shirt = "#c77dbb"; o.hair = "#e8e8e8"
	Paint.person(ci, 0, 0, o)
	var f: float = z.face
	var bob := sin(time * TAU) * 3.0 if z.type == "gary" else 0.0
	var skin := Paint.C(z.skin)
	for y in [-30.0, -23.0]:
		Paint.fill_rr(ci, f * 4 - (18 if f < 0 else 0), y + bob, 18, 6, 3, skin)
	if z.type == "gary": draw_gary(ci, f)
	else:
		# Torn hem: four teeth, retaining the character's shirt colour.
		Paint.poly(ci, [Vector2(-10,-19),Vector2(10,-19),Vector2(10,-14),Vector2(5,-17),Vector2(0,-14),Vector2(-5,-17),Vector2(-10,-14)], Paint.C(o.shirt))
		draw_prop(ci, z, f, time)
		draw_face(ci, f * 3, -45, z.state == "windup")
		if z.state == "windup": Paint.text(ci, "!", 0, -69, 20, Paint.C("#ffd54a"), Color.BLACK)
		if z.hp < z.max:
			Paint.fill_rr(ci, -17, -66, 34, 4, 2, Color(0,0,0,0.5))
			Paint.fill_rr(ci, -17, -66, 34 * maxf(0,float(z.hp)/z.max), 4, 2, Paint.C("#e23b3b"))
	ci.draw_set_transform(Vector2.ZERO)

static func draw_face(ci: CanvasItem, x: float, y: float, windup: bool = false) -> void:
	for dx in [-2.8, 2.8]:
		Paint.ell(ci, x+dx, y+2.2, 2.6, 1.4, Color(0.27,0.12,0.35,0.45))
		Paint.circ(ci, x+dx, y, 1.9, Color.WHITE)
		Paint.circ(ci, x+dx, y, 0.9, Paint.C("#c0392b"))
	ci.draw_line(Vector2(x-5,y-4.6),Vector2(x-1,y-2.6),Paint.C("#304020"),1.9)
	ci.draw_line(Vector2(x+5,y-4.6),Vector2(x+1,y-2.6),Paint.C("#304020"),1.9)
	Paint.ell(ci,x,y+6,3,3 if windup else 2,Paint.C("#302020"))
	for dx in [-1.5,0.2]: Paint.fill_rr(ci,x+dx,y+4.4,1.4,1.6,0,Color.WHITE)

static func draw_gary(ci: CanvasItem, f: float) -> void:
	for x in [-6.0,0.0,6.0]: ci.draw_line(Vector2(x,-35),Vector2(x,-17),Paint.C("#8a3a30"),1.5)
	for y in [-31.0,-25.0,-19.0]: ci.draw_line(Vector2(-9,y),Vector2(9,y),Paint.C("#8a3a30"),1.5)
	Paint.fill_rr(ci,3,-29,6,6,0,Paint.C("#e9c46a"))
	for side in [-1.0,1.0]:
		for i in 3: ci.draw_line(Vector2(side*12,-23),Vector2(side*18,-27+i*4),Paint.C("#e9c46a"),1.3)
	for i in 7:
		ci.draw_line(Vector2(-8+i*2.6,-53),Vector2(-10+i*3.3,-61-absf(i-3)),Paint.C("#e9c46a"),1.4)
	Paint.fill_rr(ci,-9,-54,18,12,5,Paint.C("#7fb04a"))
	ci.draw_line(Vector2(-10,-47),Vector2(10,-47),Color.BLACK,0.8)
	draw_face(ci,f*3,-47)
	# Burlap smile remains visible beneath the too-small rubber mask.
	ci.draw_arc(Vector2(0,-43),5,0.2,PI-0.2,12,Paint.C("#6b4423"),1.0,true)
	for i in 5: ci.draw_line(Vector2(-4+i*2,-39),Vector2(-4+i*2,-36.5),Paint.C("#6b4423"),0.8)

static func draw_prop(ci: CanvasItem, z, f: float, time: float) -> void:
	match z.type:
		"karen":
			Paint.ell(ci,-f*8,-55,20,13,Paint.C("#e8c050"))
			Paint.ell(ci,f*8,-61,15,11,Paint.C("#e8c050"))
			Paint.fill_rr(ci,-f*17-4,-22,9,8,2,Paint.C("#c0392b"))
		"lactose":
			Paint.item(ci,"milk",0,-65,0.7)
			ci.draw_line(Vector2(-9,-80),Vector2(9,-62),Paint.C("#e23b3b"),3)
		"vault":
			ci.draw_line(Vector2(f*26,-4),Vector2(-f*30,-70),Paint.C("#c99a2e"),4)
			Paint.fill_rr(ci,-6,-30,12,10,0,Color.WHITE)
			Paint.text(ci,"7",0,-21,9,Paint.C("#e23b3b"))
		"influencer":
			ci.draw_line(Vector2(f*19,-24),Vector2(f*26,-65),Paint.C("#444444"),2)
			Paint.circ(ci,f*26,-65,9+sin(time*TAU*2),Paint.C("#fff7c0",0.35))
			Paint.stroke_ell(ci,f*26,-65,11,11,Color.WHITE,2.5)
			Paint.fill_rr(ci,f*26-3,-70,6,10,1,Paint.C("#222222"))
		"flag":
			ci.draw_line(Vector2(f*22,0),Vector2(f*22,-96),Paint.C("#6b4423"),3)
			Paint.fill_rr(ci,f*22,-95,80,30,1,Paint.C("#e23b3b"))
			Paint.text(ci,"BRAINS & SAMPLES",f*22+40,-76,8.6,Color.WHITE)
		"granny":
			Paint.circ(ci,f*21,-23,5,Paint.C("#e23b3b"))
			ci.draw_line(Vector2(f*12,-23),Vector2(f*29,-32),Paint.C("#aaaaaa"),1.5)
			ci.draw_line(Vector2(f*13,-32),Vector2(f*28,-21),Paint.C("#aaaaaa"),1.5)
			for dx in [-3.0,3.0]: Paint.stroke_ell(ci,f*3+dx,-45,3,3,Paint.C("#777777"),0.8)

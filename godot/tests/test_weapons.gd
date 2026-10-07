extends SceneTree
const DT := 1.0/30
var ok := true
var checks := 0

func expect(value: bool, label: String) -> void:
	ok = value and ok; checks += 1
	print("  %s %s" % ["ok" if value else "BAD",label])

func fixture(chapter: int = 0) -> MooSim:
	var s := MooSim.new(91)
	s.autosave = false
	s.apply_state({"ver":9,"ch":chapter,"tut":{"gary":2}})
	# Clear lane alongside the crop bed, outside transfer and purchase areas.
	var a = s.mod_by("A",chapter)
	s.player.x = a.rect.x-25; s.player.y = a.rect.y+40
	return s

func actor(s: MooSim, x: float = 130, y: float = 0, type: String = "normal") -> Dictionary:
	var z := s._zombies.new_zombie(s.player.x+x,s.player.y+y,type,false,s.mod_by("C",0),3)
	s.zombies.append(z)
	return z

func shoot(s: MooSim, z: Dictionary, item: String = "corn") -> void:
	s.player.stack = {"type":item,"n":1,"inc":0}
	s.combat.cooldown = 0
	s.aim_in = (Vector2(z.x,z.y-20)-Vector2(s.player.x,s.player.y-30)).normalized()
	s.quick_shot = true
	for i in 15: s.upd_combat(DT); s.upd_combat_timers(DT)

func weapons() -> void:
	for chapter in 3:
		var s := fixture(chapter)
		var gun = s.pads.filter(func(p): return p.d == chapter and p.fx == "gun")[0]
		expect(s.visible_pads().has(gun) and not s.visible_pads().any(func(p): return p.d == chapter and p.fx == "gun_damage"),"ch%d base visible, upgrades require base" % chapter)
		s.S.money = gun.cost
		s.player.x = gun.x+gun.w/2; s.player.y = gun.y+gun.h/2
		for i in 40: s.act()
		expect(gun.paid == gun.cost and s.S.gun == chapter+1 and s.S.money == 0,"ch%d actual earned-payment armory purchase" % chapter)
		var w := s.weapon_stats()
		expect(w.damage == [1,2,4][chapter] and w.cd == [0.45,0.6,0.7][chapter] and w.range == [230,280,300][chapter],"ch%d base stats" % chapter)
		var upgrades := s.pads.filter(func(p): return p.d == chapter and p.fx in ["gun_damage","gun_speed"])
		for pad in upgrades:
			s.S.money = pad.cost; s.player.x = pad.x+pad.w/2; s.player.y = pad.y+pad.h/2
			for i in 40: s.act()
		w = s.weapon_stats()
		expect(w.damage == [1.5,3,6][chapter] and is_equal_approx(w.cd,[0.3375,0.45,0.525][chapter]),"ch%d both actual upgrade pads" % chapter)
		var saved := s.snapshot()
		s.apply_state(saved)
		expect(s.S.gun == chapter+1 and s.weapon_stats().damage == w.damage and s.weapon_stats().cd == w.cd,"ch%d weapon and upgrades reload from paid keys" % chapter)
		s.dispose()

func hp_and_projectiles() -> void:
	for chapter in 3:
		var s := fixture(chapter)
		s.S.gun = chapter+1
		var z := actor(s)
		for i in 2: shoot(s,z)
		expect(z in s.zombies,"ch%d survives two delivered projectiles" % chapter)
		shoot(s,z)
		expect(z not in s.zombies,"ch%d third delivered projectile cures" % chapter)
		if chapter > 0:
			s.S.gun = chapter
			z = actor(s)
			for i in 5: shoot(s,z)
			expect(z in s.zombies,"ch%d previous weapon needs six hits" % chapter)
			shoot(s,z)
			expect(z not in s.zombies,"ch%d sixth previous-weapon projectile cures" % chapter)
		s.S.gun = chapter+1
		var primary := actor(s,100)
		var secondary := actor(s,100,45)
		shoot(s,primary)
		expect(primary.hp == [2,4,8][chapter] and secondary.hp == [3,5,10][chapter],"ch%d primary/splash damage applied once" % chapter)
		s.dispose()
	var s := fixture()
	s.S.gun = 1
	var z := actor(s,110,0,"lactose")
	shoot(s,z,"milk")
	expect(z not in s.zombies,"milk lactose multiplier cures in one real shot")
	z = actor(s,110,0,"gary"); s.S.tut.gary = 1
	shoot(s,z)
	expect(s.S.tut.gary == 2 and s.S.hearts == 5,"real projectile finishes harmless Gary")
	s.zombies.clear(); z = actor(s,120)
	var direction := (Vector2(z.x,z.y-20)-Vector2(s.player.x,s.player.y-30)).normalized()
	expect(s._combat.target(direction.rotated(deg_to_rad(13)),230) == z and s._combat.target(direction.rotated(deg_to_rad(15)),230) == null,"assist accepts 13 degrees and rejects 15")
	expect(s._combat.target(direction,100) == null,"assist rejects out-of-range actor")
	s.player.stack = {"type":"corn","n":10,"inc":0}; s.aim_in = direction; s.fire_in = true; s.combat.cooldown = 0
	var before: int = s.player.stack.n
	for i in 13: s.upd_combat_timers(DT); s.upd_combat(DT)
	expect(s.player.stack.n == before-1,"held fire obeys 0.45s cooldown")
	for i in 2: s.quick_shot = true; s.upd_combat(DT)
	expect(s.player.stack.n == before-1,"quick taps cannot reset cooldown")
	s.clear_combat_input(); s.shots.clear(); s.zombies.clear()
	s.player.stack = {"type":"egg","n":1,"inc":0}; s.combat.cooldown = 0; s.aim_in = Vector2.RIGHT; s.quick_shot = true
	s.upd_combat(1)
	expect(s.shots.is_empty() and s.player.stack.n == 0,"large tick projectile expires exactly at range")
	# Crossing a target over an entire large tick must still collide.
	z = actor(s,180); s.player.stack = {"type":"egg","n":1,"inc":0}; s.combat.cooldown = 0; s.quick_shot = true
	s.upd_combat(0.4)
	expect(z.hp == 2,"swept collision prevents tunneling")
	s.dispose()

func reservations_dash_saves() -> void:
	var s := fixture()
	s.S.gun = 1; s.player.stack = {"type":"milk","n":1,"inc":0}
	s.stack_fly("milk",{"x":s.player.x,"y":s.player.y},s.player)
	s.aim_in = Vector2.RIGHT; s.quick_shot = true; s.upd_combat(DT)
	expect(s.player.stack.n == 1 and s.player.stack.inc == 1 and s.player.stack.pending_ids.size() == 1,"fire consumes arrived item and keeps pending pickup")
	s.combat.cooldown = 0; s.quick_shot = true; s.upd_combat(DT)
	expect(s.player.stack.n == 1 and s.shots.size() == 1,"pending item cannot fire")
	s.update(0.3)
	expect(s.player.stack.n == 1 and s.player.stack.inc == 0,"reserved pickup arrives once after firing")
	s.move_in = Vector2.DOWN*0.2
	var start := Vector2(s.player.x,s.player.y)
	expect(s.try_dash(),"dash starts")
	for i in 6: s.update(0.03)
	var length := Vector2(s.player.x,s.player.y).distance_to(start)
	expect(is_equal_approx(length,230*2.6*0.18) and not s.try_dash(),"dash 2.6x for .18s even with partial stick and rejects reuse")
	expect(not s.hurt_player("dash test"),"dash grants .33s damage immunity")
	for i in 78: s.upd_combat_timers(0.03)
	expect(s.try_dash(),"dash becomes available after 2.5s")
	var snap := s.snapshot(); var gun: int = s.S.gun
	s.apply_state(snap)
	expect(s.S.gun == gun and s.shots.is_empty() and not s.fire_in and s.aim_in == Vector2.ZERO and s.combat.dash_cd > 0,"cold reload keeps cooldown but clears shots and input")
	# Historical array saves must map economic pads across newly inserted armories.
	for count in [10,22,34]:
		var old := s.pads.filter(func(p): return not p.get("combat",false))
		var paid: Array = []
		for i in count: paid.append(old[i].cost-1)
		s.apply_state({"ver":9,"paid":paid,"ch":2,"money":123})
		var economic := s.pads.filter(func(p): return not p.get("combat",false))
		var good: bool = s.S.money == 123 and s.S.gun == 0
		for i in count: good = good and economic[i].paid == paid[i]
		expect(good,"old %d economic-pad array retains partial payments" % count)
	# Dusk rollback restores gun payments/cooldowns with the inventory.
	var gunpad = s.pads.filter(func(p): return p.d == 0 and p.fx == "gun")[0]
	gunpad.paid = gunpad.cost; s.apply_pad(gunpad,true)
	s.player.stack = {"type":"milk","n":4,"inc":0}
	s.capture_checkpoint("dusk")
	var upgrade = s.pads.filter(func(p): return p.d == 0 and p.fx == "gun_damage")[0]
	upgrade.paid = upgrade.cost; s.apply_pad(upgrade,true)
	s.player.stack.n = 0; s.faint = {"cause":"test","checkpoint":"dusk"}
	expect(s.restore_checkpoint() and s.S.gun == 1 and s.weapon_stats().damage == 1 and s.player.stack.n == 4,"retry rolls back upgrades and spent ammunition to dusk")
	var vault := actor(s,100,0,"vault")
	vault.vaulted = true; vault.vault = 0.55
	s.hit_zombie(vault,1,"corn")
	var knock: float = vault.kbt
	s.upd_zombies(DT)
	expect(vault.kbt < knock and vault.vault == 0.55,"Vaulter hit applies immediate knockback before burst chase")
	vault.state = "windup"; vault.st = 0.55
	s.hit_zombie(vault,0.1,"corn")
	expect(vault.state == "recover" and vault.st == 0.5,"weapon hit interrupts a winding bite with recovery")
	# A real winding bite is dodged with dash immunity and collision still holds.
	s.zombies.clear(); var biting := actor(s,5)
	biting.state = "windup"; biting.st = 0.02
	s.move_in = Vector2.DOWN; s.combat.dash_cd = 0; s.try_dash(); s.update(DT)
	expect(s.S.hearts == 5,"dash dodges an actual completed bite windup")
	var wall = s.mod_by("C",0).bench
	s.player.x = wall.x+wall.w/2; s.player.y = wall.y-16
	s.move_in = Vector2.DOWN; s.combat.dash_cd = 0; s.try_dash()
	for i in 4: s.update(0.05)
	expect(s.player.y < wall.y and not s.blocked_at(s.player.x,s.player.y,8),"dash cannot cross the solid counter")
	s.zombies.clear(); s.S.gun = 3; s.combat.cooldown = 0
	var primary := actor(s,120); primary.hp = 1
	var other := actor(s,120,35); other.hp = 1
	var third := actor(s,120,-35); third.hp = 1
	shoot(s,primary)
	expect(s.zombies.is_empty() and s.events.filter(func(e): return e.kind == "zombie_cured").size() == 3,"Pie splash cures three actors exactly once")
	s.dispose()

func _init() -> void:
	weapons(); hp_and_projectiles(); reservations_dash_saves()
	print(("PASS" if ok else "FAIL")+" weapons %d checks" % checks)
	quit(0 if ok else 1)

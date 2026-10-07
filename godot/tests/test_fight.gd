extends SceneTree
const DT := 1.0/30
var ok := true

func _init() -> void:
	for chapter in 3:
		var wins := 0
		var cures := 0
		var hits := 0
		for seed_value in range(10):
			var s := MooSim.new(seed_value+400)
			s.autosave = false
			# Combat fixture starts with an owned chapter/base weapon and empty hands.
			# Its first real night uses actual waves, bite damage, crop reload and input.
			s.apply_state({"ver":9,"ch":chapter,"time":0.6999,"cn":1 if chapter == 0 else 0,"day":2 if chapter == 0 else 1,"tut":{"gary":2},"gun":chapter+1})
			var field = s.mod_by("A",chapter).rect
			s.player.x = field.x+25; s.player.y = field.y+25
			var bot := MooFightBot.new(s)
			for i in 3100:
				bot.tick(); s.update(DT)
				if s.faint != null or s.S.time < 0.1: break
			if s.faint == null and s.S.time < 0.1: wins += 1
			cures += int(s.S.stats.get("cures",0)); hits += bot.damage_taken
			print("  fight ch%d seed%d hearts=%d cures=%d hits=%d t=%.1f" % [chapter+1,seed_value,s.S.hearts,s.S.stats.get("cures",0),bot.damage_taken,s.T])
			s.dispose()
		ok = ok and wins >= 7 and cures >= 10
		print("  ch%d normal-night survival %d/10 cures=%d hits=%d" % [chapter+1,wins,cures,hits])
	print(("PASS" if ok else "FAIL")+" fight: base weapons, actual crop reload and damage across 30 normal nights; bosses follow S4")
	quit(0 if ok else 1)

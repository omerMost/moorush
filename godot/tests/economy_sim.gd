class_name MooEconomySim
extends MooSim
## Production/navigation regression fixture; real-damage normal-night fight bots run separately.
## Real MooSim bites are covered by test_hearts test_fight and rendered faint/retry/weapon play.
func hurt_player(_cause: String, _damage: int = 1) -> bool:
	return false

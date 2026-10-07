class_name MooEconomySim
extends MooSim
## Production/navigation regression fixture; armed fight bots follow in S3.
## Real MooSim bites are covered by test_hearts and the rendered faint/retry test.
func hurt_player(_cause: String, _damage: int = 1) -> bool:
	return false

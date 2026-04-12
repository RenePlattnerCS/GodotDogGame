# upgrade_charge.gd
extends Upgrade
class_name UpgradeCharge

@export var charge_reduction: float = 0.2

func apply(player: CharacterBody2D):
	player.decrease_dog_chargetime()
	#.max_charge_time -= charge_reduction

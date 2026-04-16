# upgrade_charge.gd
extends Upgrade
class_name UpgradeCharge

@export var charge_reduction: float = 0.1

func apply(player: Node2D):
	player.get_node("Sprites/Dog").decrease_charge_time()
	#.max_charge_time -= charge_reduction

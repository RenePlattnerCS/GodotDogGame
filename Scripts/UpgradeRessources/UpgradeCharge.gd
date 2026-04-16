# upgrade_charge.gd
extends Upgrade
class_name UpgradeCharge

@export var charge_reduction_mult: float = 1.2

func apply(player: Node2D):
	player.get_node("Sprites/Dog").decrease_charge_time(charge_reduction_mult)

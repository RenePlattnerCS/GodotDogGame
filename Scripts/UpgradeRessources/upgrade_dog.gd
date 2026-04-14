# upgrade_punch.gd
extends Upgrade
class_name UpgradePunch

@export var knockback_bonus: float = 2000.0

func apply(player: Node2D):
	print("strenght upgraded")
	player.get_node("Sprites/Dog").increase_knockback(knockback_bonus)  

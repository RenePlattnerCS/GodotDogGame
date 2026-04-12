# upgrade_punch.gd
extends Upgrade
class_name UpgradePunch

@export var knockback_bonus: float = 2000.0

func apply(player: CharacterBody2D):
	print("strenght upgraded")
	player.increase_dog_knockback(knockback_bonus)  

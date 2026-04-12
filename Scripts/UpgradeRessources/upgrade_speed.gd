# upgrade_speed.gd
extends Upgrade
class_name UpgradeSpeed

@export var speed_bonus: float = 50.0

func apply(player: CharacterBody2D):
	print("speed upgraded")
	player.SPEED += speed_bonus

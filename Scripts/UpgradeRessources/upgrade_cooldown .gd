extends Upgrade
class_name UpgradeCooldown

@export var speed_retraction_bonus: float = 150.0

func apply(player: Node2D):
	player.get_node("Sprites/Dog").decrease_retraction(speed_retraction_bonus)

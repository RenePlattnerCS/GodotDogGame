extends Upgrade
class_name UpgradeLength

@export var length_bonus: float = 70.0
@export var speed_extend_bonus: float = 50.0
@export var speed_retract_bonus: float = 60.0

func apply(player: Node2D):
	print("length increased")
	player.get_node("Sprites/Dog").increase_length(length_bonus, speed_extend_bonus, speed_retract_bonus)

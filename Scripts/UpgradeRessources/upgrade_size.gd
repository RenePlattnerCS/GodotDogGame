extends Upgrade
class_name UpgradeSize

@export var size_bonus: float = 0.1

func apply(player: Node2D):
	print("size  increased")
	player.get_node("Sprites/Dog").increase_size(size_bonus)

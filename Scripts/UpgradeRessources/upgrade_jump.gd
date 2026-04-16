# upgrade_jump.gd
extends Upgrade
class_name UpgradeJump

@export var jump_bonus: float = 35.0

func apply(player: CharacterBody2D):
	player.JUMP_VELOCITY -= jump_bonus  # more negative = higher jump
	player.jump_upgraded = true

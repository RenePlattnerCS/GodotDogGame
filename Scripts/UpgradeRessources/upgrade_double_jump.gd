# upgrade_jump.gd
extends Upgrade
class_name UpgradeDoubleJump

func apply(player: CharacterBody2D):
	player.number_of_jumps += 1

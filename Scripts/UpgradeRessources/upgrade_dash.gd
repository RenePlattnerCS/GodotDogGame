# upgrade_jump.gd
extends Upgrade
class_name UpgradeDash

func apply(player: CharacterBody2D):
	print("dash unlocked")
	player.unlocked_dash = true

# upgrade_jump.gd
extends Upgrade
class_name UpgradeDash

func apply(player: CharacterBody2D):
	player.unlocked_dash = true

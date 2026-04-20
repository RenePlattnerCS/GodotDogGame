# upgrade_jump.gd
extends Upgrade
class_name UpgradeDoubleJump

func apply(player: CharacterBody2D):
	print("upgrade double jump: " , player.number_of_jumps)
	player.number_of_jumps += 1
	player.jumps_remaining = player.number_of_jumps
	print("upgraded : " , player.number_of_jumps)

extends Node2D

const ALL_UPGRADES = [
	preload("res://Upgrades/jump.tres"),
	preload("res://Upgrades/charge.tres"),
	preload("res://Upgrades/speed.tres"),
	preload("res://Upgrades/srength.tres"),
	preload("res://Upgrades/length.tres"),
	preload("res://Upgrades/size.tres"),
	preload("res://Upgrades/cooldown.tres"),
	preload("res://Upgrades/double_jump.tres"),
	preload("res://Upgrades/dash.tres"),
]

func get_random_upgrades(count: int = 2) -> Array:
	var shuffled = ALL_UPGRADES.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, count)

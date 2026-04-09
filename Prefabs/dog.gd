extends Node2D


@export var dog_length: float = 0.0  # drag this slider in Inspector!

const BASE_MIDDLE_WIDTH = 15.0  # match your sprite
const FRONT_WIDTH = 15


func _process(delta):
	update_dog()

func update_dog():
	# middle stretches left
	$Middle.scale.x = (BASE_MIDDLE_WIDTH + dog_length) / BASE_MIDDLE_WIDTH
	
	# front follows the left edge
	$Front.position.x = $Back.position.x + dog_length #+ FRONT_WIDTH

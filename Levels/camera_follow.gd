extends Camera2D

@export var player: CharacterBody2D
@export var camera_speed: float = 5.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player:
		return
	# get dog front world position
	var dog = player.get_node("Sprites/Dog/Front")
	if not dog:
		print("dog not found")
		return
	var dog_pos = 	dog.global_position
	var player_pos = player.global_position
	var midpoint = (player_pos + dog_pos) / 2.0
	global_position = global_position.lerp(midpoint, camera_speed * delta)

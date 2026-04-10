extends Camera2D

@export var player1: CharacterBody2D
@export var player2: CharacterBody2D

@export var camera_speed: float = 5.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player1 or not player2:
		print("player was not assigned in camera!")
		return

	var player_1pos = player1.global_position
	var player_2pos = player2.global_position
	var midpoint = (player_1pos + player_2pos) / 2.0
	global_position = global_position.lerp(midpoint, camera_speed * delta)

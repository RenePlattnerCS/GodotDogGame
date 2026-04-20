extends Sprite2D
class_name Missile


@onready var hitbox = $Hitbox


	
	
var speed: float = 100.0
var fire_direction: float = 1.0
var launch_position: Vector2
var current_length: float = 0.0
var target_length: float = 1200.0
var player_index: int = -1
var knockback_strength: float = 4000.0
var knockback_up: float = 600.0

const EXTEND_LENGTH_OFFSET = 20.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox.area_entered.connect(on_reflector_entered)
	
	
func setup(p_position: Vector2, p_direction: float, p_speed: float, p_scale: Vector2, p_target_length: float, p_player_index: int, p_knockback_strength: float, p_knockback_up: float):
	global_position = p_position
	fire_direction = p_direction
	speed = p_speed
	scale = p_scale
	target_length = p_target_length
	player_index = p_player_index
	knockback_strength = p_knockback_strength
	knockback_up = p_knockback_up
	launch_position = p_position

func _process(delta):
	current_length = move_toward(current_length, target_length, speed * delta)
	speed += delta * speed
	global_position.x = launch_position.x + current_length * fire_direction

	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		queue_free()

func _on_hitbox_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	if body.player_index == player_index:
		return
	var knock_direction = sign(body.global_position.x - global_position.x)
	var force = knockback_strength * 1.4
	body.velocity.x = knock_direction * force
	body.velocity.y = -knockback_up
	body.is_knocked_back = true
	queue_free()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_reflector_entered(area : Area2D):
	print("Area entered!!!!!!!!!!!")
	if not area.is_in_group("reflector"):
		return
	if (player_index ==1):
		player_index = 2
	else:
		player_index = 1
	fire_direction = -1 * fire_direction

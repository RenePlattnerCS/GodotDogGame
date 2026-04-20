extends Sprite2D
class_name Missile


@onready var hitbox = $Hitbox

var player : Node2D

var speed: float = 100.0
var fire_direction: float = 1.0
var launch_position: Vector2
var current_length: float = 0.0
var target_length: float = 1200.0
var player_index: int = -1
var knockback_strength: float = 4000.0
var knockback_up: float = 600.0
var charge_percent: float = 0.0
const EXTEND_LENGTH_OFFSET = 20.0
const KNOCKBACK_MULT : float = 1.6
const FLASH_COUNT = 3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox.area_entered.connect(on_reflector_entered)
	hitbox.is_active = true
	
	
func setup(p_position: Vector2, p_direction: float, p_speed: float, p_scale: Vector2, p_target_length: float, p_player_index: int, p_knockback_strength: float, p_knockback_up: float, p_player : Node2D, p_charge_percent : float):
	player = p_player
	charge_percent = p_charge_percent
	global_position = p_position
	fire_direction = p_direction
	
	speed = p_speed
	scale = p_scale
	scale.x = scale.x * sign(p_direction)
	target_length = p_target_length
	player_index = p_player_index
	knockback_strength = p_knockback_strength
	knockback_up = p_knockback_up
	launch_position = p_position

func _process(delta):
	current_length = move_toward(current_length, target_length, speed * delta)
	speed += delta * speed
	global_position.x = launch_position.x + (current_length * sign(fire_direction))

	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		queue_free()

func _on_hitbox_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	if body.player_index == player_index:
		return
	var knock_direction = sign(body.global_position.x - global_position.x)
	#var force = knockback_strength * 1.4
	charge_percent = clamp(charge_percent, 0.3, 1.0)
	apply_knockback(body, knock_direction, charge_percent,KNOCKBACK_MULT)


#--------------


# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_reflector_entered(area : Area2D):
	
	if not area.is_in_group("reflector"):
		return
	if (player_index ==1):
		player_index = 2
	else:
		player_index = 1
	fire_direction = -1 * fire_direction
	launch_position = global_position
	current_length = 0.0
#---------


func apply_knockback(body: CharacterBody2D, knock_direction: float, charge_percent: float, knockback_mult : float = 0.8):
	
	var force = lerp(100.0 * 0.8, knockback_strength * knockback_mult, charge_percent)
	var force_up = lerp(50.0, knockback_up * 0.7, charge_percent)
	
	await hitlag(body)
	
	body.velocity.x = knock_direction * force
	body.velocity.y = -force_up
	body.is_knocked_back = true
	

# ─── hitlag ───────────────────────────────────────────────────────────────────

func hitlag(body: CharacterBody2D):
	
	var hitlag_duration = lerp(0.05, 0.15, charge_percent)


	if hitlag_duration <= 0:
		return

	# freeze both bodies
	var body_vel = body.velocity
	var self_vel = player.velocity  # player
	body.velocity = Vector2.ZERO
	player.velocity = Vector2.ZERO
	body.set_physics_process(false)
	player.set_physics_process(false)
	set_process(false)

	# flash effect
	var flash_time = hitlag_duration / (FLASH_COUNT * 2)
	for i in FLASH_COUNT:
		body.modulate = Color.RED
		await get_tree().create_timer(flash_time, true, false, true).timeout
		body.modulate = Color.WHITE
		await get_tree().create_timer(flash_time, true, false, true).timeout

	# unfreeze
	body.set_physics_process(true)
	player.set_physics_process(true)
	set_process(true)
	body.modulate = Color.WHITE

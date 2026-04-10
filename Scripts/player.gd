extends CharacterBody2D


@export var player_index: int = 1

@export_group("Movement")
@export var air_resistance: float = 0.95  # closer to 1.0 = more slippery
@export var ground_slide_friction: float = 0.95  # closer to 1.0 = more slide
@export var knockback_threshold: float = 70.0  # when to exit knockback state

@export_group("Jump")
@export var fall_multiplier : float = 1.5
@export var low_jump_multiplier: float = 5.0  # when button released early
@export var max_jump_time: float = 1.3  # max time you can hold jump

var jump_timer: float = 0.0
var is_jumping: bool = false
var player_has_horizontal_speed : bool = false

var is_knocked_back: bool = false

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const EPSILON = 1.0


func _ready():
	$Sprites/HandAnimation.play("idle")
	$Sprites/BodyAnimation.play("idle")
	$Sprites/DogBounceAnimationPlayer.play("idle")

func _process(delta: float) -> void:
	player_has_horizontal_speed = abs(velocity.x) > EPSILON
	if(player_has_horizontal_speed and not is_knocked_back):
		$Sprites/HandAnimation.play("walking")
		$Sprites/BodyAnimation.play("walking")
		$Sprites/DogBounceAnimationPlayer.play("walking")
		
	else:
		$Sprites/HandAnimation.play("idle")
		$Sprites/BodyAnimation.play("idle")
		$Sprites/DogBounceAnimationPlayer.play("idle")
		
			

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if Input.is_action_just_released(get_input_action("jump")):
			is_jumping = false
		
		if is_jumping:
			jump_timer += delta
			# force descend if held too long
			if jump_timer >= max_jump_time:
				is_jumping = false
				
		if velocity.y > 0:  # descending
			velocity += get_gravity() * delta * fall_multiplier
		elif not is_jumping and velocity.y < 0:
			# ascending but button released early — pull down faster
			velocity += get_gravity() * delta * low_jump_multiplier
		else:  # ascending and button still held — normal gravity
			velocity += get_gravity() * delta
		if is_knocked_back:
			# slow air resistance instead of instant stop
			velocity.x *= air_resistance
	else:		
		is_jumping = false
		jump_timer = 0.0
		
	if is_knocked_back:
	 	# slide on ground instead of stopping
		velocity.x *= ground_slide_friction
		# exit knockback when slow enough
		if abs(velocity.x) < knockback_threshold:
			is_knocked_back = false
			
	elif not is_jumping:
		# normal movement
		var direction = Input.get_axis(get_input_action(("left")), get_input_action(("right")))
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		player_has_horizontal_speed = abs(velocity.x) > EPSILON
		if(player_has_horizontal_speed and not is_knocked_back):
			$Sprites.scale.x = sign(velocity.x)

	if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_timer = 0.0
	
	
	move_and_slide()
	
func get_input_action(action: String) -> String:
	return "p" + str(player_index) + "_" + action
	

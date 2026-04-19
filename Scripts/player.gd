extends CharacterBody2D


@export var player_index: int = 1
@export var spawn_point: Node2D 

@export_group("Movement")
@export var air_resistance: float = 0.95  # closer to 1.0 = more slippery
@export var ground_slide_friction: float = 0.95  # closer to 1.0 = more slide
@export var knockback_threshold: float = 70.0  # when to exit knockback state
@export var dash_slide_timer: float = 0.3

@export_group("Jump")
@export var fall_multiplier : float = 1.5
@export var low_jump_multiplier: float = 2.0  # when button released early
@export var max_jump_time: float = 0.8  # max time you can hold jump
@export var lock_jump_after_time: float = 0.2  # max time you can hold jump

var jump_timer: float = 0.0
var is_jumping: bool = false
var lock_jump: bool = false
var jump_upgraded: bool = false
var dash_timer: float = 0.0
var fast_fall_multiplier : float = 1
const BASE_FAST_FALL_MULT = 2
const APEX_THRESHOLD = 10.0  
var player_has_horizontal_speed : bool = false

var is_knocked_back: bool = false
var is_dashing: bool = false
var lock_turning_around: bool = false

var SPEED = 150.0
var JUMP_VELOCITY = -400.0
const EPSILON = 1.0
const STRAIGHT_DOWN_THREASHOLD = 0.8

var number_of_jumps : int = 1
var jumps_remaining: int = 1

func _ready():
	$Sprites/HandAnimation.play("idle")
	$Sprites/BodyAnimation.play("idle")
	$Sprites/DogBounceAnimationPlayer.play("idle")
	
	$NormalHurtbox.disabled = false
	$JumpingHurtbox.disabled = true


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
		
	
		if Input.is_action_just_released(get_input_action("jump")) and not lock_jump:
			is_jumping = false
		
		if is_jumping:

			jump_timer += delta
			# force descend if held too long
			if jump_timer >= max_jump_time:
				is_jumping = false
				
			
			if jump_timer >= lock_jump_after_time:
				if not jump_upgraded :
					lock_jump = true
				$NormalHurtbox.disabled = true
				$JumpingHurtbox.disabled = false
		
		if velocity.y < 0 and velocity.y > -APEX_THRESHOLD:  # ascending, near apex
			var stick = Input.get_vector(get_input_action("left"), get_input_action("right"), get_input_action("up"), get_input_action("down"))
			if stick.y > STRAIGHT_DOWN_THREASHOLD:
				fast_fall_multiplier = BASE_FAST_FALL_MULT
				
		if velocity.y > 0:  # descending
			var stick = Input.get_vector(get_input_action("left"),get_input_action("right"),get_input_action("up"), get_input_action("down"))
			if stick.y > STRAIGHT_DOWN_THREASHOLD:
				fast_fall_multiplier = BASE_FAST_FALL_MULT
			velocity += get_gravity() * delta * fall_multiplier * fast_fall_multiplier
		elif not is_jumping and velocity.y < 0:
			# ascending but button released early — pull down faster
			velocity += get_gravity() * delta * low_jump_multiplier
		else:  # ascending and button still held — normal gravity
			velocity += get_gravity() * delta
		if is_knocked_back:
			# slow air resistance instead of instant stop
			velocity.x *= air_resistance
	else:	 # ----------------is_on_floor()-------------------
		jumps_remaining = number_of_jumps
		is_jumping = false
		lock_jump = false
		jump_timer = 0.0
		fast_fall_multiplier = 1
		$NormalHurtbox.disabled = false
		$JumpingHurtbox.disabled = true
		
		
	if is_knocked_back or is_dashing:
	 	# slide on ground instead of stopping
		velocity.x *= ground_slide_friction
		if is_dashing:
			dash_timer += delta
		# exit knockback when slow enough
		if abs(velocity.x) < knockback_threshold:
			is_knocked_back = false
			is_dashing = false
			dash_timer = 0.0
		if dash_timer > dash_slide_timer:
			if (Input.get_axis(get_input_action("left"), get_input_action("right"))):
				is_dashing = false
				dash_timer = 0.0
			
	elif (not is_jumping and not lock_jump) or jump_upgraded:
		# normal movement
		var direction = 0
		if(not lock_turning_around):
			direction = Input.get_axis(get_input_action(("left")), get_input_action(("right")))
		if(lock_turning_around):
			var locked_dir = direction
			if(locked_dir == 0.0):
				locked_dir = $Sprites.scale.x
			direction = Input.get_axis(get_input_action(("left")), get_input_action(("right")))
			if(locked_dir >=0):
				direction = clamp(direction,0,1)
			else:
				direction = clamp(direction,-1,0)	
			
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		player_has_horizontal_speed = abs(velocity.x) > EPSILON
		if(player_has_horizontal_speed and not is_knocked_back):
			$Sprites.scale.x = sign(velocity.x)

	if Input.is_action_just_pressed(get_input_action("jump")):
		if is_on_floor():
			jumps_remaining = number_of_jumps -1
			velocity.y = JUMP_VELOCITY
			is_dashing = false
			is_jumping = true
			jump_timer = 0.0
		elif jumps_remaining > 0:
			jumps_remaining -= 1
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			jump_timer = 0.0
			lock_jump = false  # reset so the new jump can be held
	
	
	move_and_slide()
	
func get_input_action(action: String) -> String:
	return "p" + str(player_index) + "_" + action
	
	
	
func disable_player():
	visible = false
	set_process(false)        # disables _process
	set_physics_process(false) # disables _physics_process
	
	

func respawn():
	if(not spawn_point):
		print("no sawn point assigned")
		return
	global_position = spawn_point.position
	lock_turning_around = false
	visible = true
	set_process(true)
	set_physics_process(true)
	velocity = Vector2.ZERO
	is_knocked_back = false

func get_cur_dog():
	return $Sprites/Dog.get_child(0)

func switch_arms():
	var show_hand = not $Sprites/Dog/soloArm.visible
	$Sprites/Dog/soloArm.visible = show_hand
	$Sprites/HandAnimation.visible = not show_hand

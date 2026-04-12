extends CharacterBody2D


@export var player_index: int = 1
@export var spawn_point: Node2D 

@export_group("Movement")
@export var air_resistance: float = 0.95  # closer to 1.0 = more slippery
@export var ground_slide_friction: float = 0.95  # closer to 1.0 = more slide
@export var knockback_threshold: float = 70.0  # when to exit knockback state

@export_group("Jump")
@export var fall_multiplier : float = 1.5
@export var low_jump_multiplier: float = 5.0  # when button released early
@export var max_jump_time: float = 0.8  # max time you can hold jump
@export var lock_jump_after_time: float = 0.2  # max time you can hold jump

var jump_timer: float = 0.0
var is_jumping: bool = false
var lock_jump: bool = false
var jump_upgraded: bool = false


var player_has_horizontal_speed : bool = false

var is_knocked_back: bool = false

var SPEED = 150.0
var  JUMP_VELOCITY = -400.0
const EPSILON = 1.0


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
					print("lock jump")
					lock_jump = true
				$NormalHurtbox.disabled = true
				$JumpingHurtbox.disabled = false
				
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
		if $DownRayCast2D.is_colliding():
			var body = $DownRayCast2D.get_collider()
			if body:  # always null check first!
				if body.is_in_group("crumble_tile"):
					body.crumble()
		#print("unlock jump")
		is_jumping = false
		lock_jump = false
		jump_timer = 0.0
		$NormalHurtbox.disabled = false
		$JumpingHurtbox.disabled = true
		
		
	if is_knocked_back:
	 	# slide on ground instead of stopping
		velocity.x *= ground_slide_friction
		# exit knockback when slow enough
		if abs(velocity.x) < knockback_threshold:
			is_knocked_back = false
			
	elif (not is_jumping and not lock_jump) or jump_upgraded:
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
	
	
	
func disable_player():
	visible = false
	set_process(false)        # disables _process
	set_physics_process(false) # disables _physics_process
	
	
func increase_dog_knockback(added_strength : int):
	$Sprites/Dog.stats.knockback_strength += added_strength
	$Sprites/Dog.apply_stats()
	
func decrease_dog_chargetime():
	$Sprites/Dog.stats.charge_speed_multiplier *= 2
	$Sprites/Dog.apply_stats()
	
func increase_dog_length(length : int, extend_speed : int,  retract_speed : int):
	$Sprites/Dog.stats.max_length += length
	$Sprites/Dog.stats.extend_speed +=extend_speed
	$Sprites/Dog.stats.retract_speed += retract_speed
	$Sprites/Dog.apply_stats()


func respawn():
	if(not spawn_point):
		print("no sawn point assigned")
		return
	global_position = spawn_point.position
	
	visible = true
	set_process(true)
	set_physics_process(true)
	velocity = Vector2.ZERO
	is_knocked_back = false

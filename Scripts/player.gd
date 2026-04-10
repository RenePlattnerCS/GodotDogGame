extends CharacterBody2D


@export var player_index: int = 1

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const EPSILON = 1.0

#var facing_direction : int = 1

func _ready():
	$Sprites/HandAnimation.play("idle")
	$Sprites/BodyAnimation.play("idle")
	$Sprites/DogBounceAnimationPlayer.play("idle")

func _process(delta: float) -> void:
	var player_has_horizontal_speed : bool = abs(velocity.x) > EPSILON
	if(player_has_horizontal_speed):
		$Sprites/HandAnimation.play("walking")
		$Sprites/BodyAnimation.play("walking")
		$Sprites/DogBounceAnimationPlayer.play("walking")
		#if (facing_direction != $Sprites.scale.x):
		#	print("flip!")
		$Sprites.scale.x = sign(velocity.x)
	else:
		$Sprites/HandAnimation.play("idle")
		$Sprites/BodyAnimation.play("idle")
		$Sprites/DogBounceAnimationPlayer.play("idle")
		
			

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis(get_input_action("left"), get_input_action("right"))
	if direction:
	#	facing_direction = direction
		velocity.x = direction * SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
func get_input_action(action: String) -> String:
	return "p" + str(player_index) + "_" + action
	

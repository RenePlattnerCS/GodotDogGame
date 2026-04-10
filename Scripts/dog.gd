extends Node2D


@export var max_charge_time: float = 1.0
@export var max_keep_charging_time: float = 3.0
@export var max_length: float = 170.0
@export var extend_speed: float = 700.0
@export var retract_speed: float = 300.0
@export var retract_ease_speed: float = 5.0 
@export var min_extend_length: float = 30.0
@export var charging_retraction_length: float = 15.0
@export var buffer_time: float = 0.4  

@export var knockback_up: float = 200
@export var knockback_stength: float = 1800 

const RETRACT_LENGTH_OFFSET = 1.0
const EXTEND_LENGTH_OFFSET = 20.0
const EASE_IN_LENGTH = 20.0
const KNOCKBACK_MIN_STRENGTH = 300.0
const KNOCKBACK_UP_MIN_STRENGTH = 50.0

var player_index: int = -1
var charge_time: float = 0.0
var is_charging: bool = false
var is_extending: bool = false

var current_length: float = 0.0
var target_length: float = 0.0

var input_buffer: bool = false
var buffer_timer: float = 0.0


enum DogState {IDLE, CHARGING, EXTENDING, RETRACTING}
var state: DogState = DogState.IDLE

const BASE_MIDDLE_WIDTH = 15.0  # match your sprite
const FRONT_WIDTH = 15

func _ready():
	player_index = get_parent().get_parent().player_index
	if (player_index == -1 ):
		print("coudnt find player index")

func _process(delta):
	process_dog_state(delta)
	update_dog()


func update_dog():
	# middle stretches left
	$Middle.scale.x = (BASE_MIDDLE_WIDTH + current_length) / BASE_MIDDLE_WIDTH
	
	# front follows the left edge
	$Front.position.x = $Back.position.x + current_length #+ FRONT_WIDTH


func process_dog_state(delta):
	# buffer the input with a timer
	if Input.is_action_just_pressed(get_input_action("shoot")):
		input_buffer = true
		buffer_timer = buffer_time
	
	# count down the buffer timer
	if input_buffer:
		buffer_timer -= delta
		if buffer_timer <= 0.0:
			input_buffer = false  # buffer expired, too late!
			
	match state:
		DogState.IDLE:
			#print("dog iddle")
			# only accept input when fully retracted
			if input_buffer:
				input_buffer = false
				target_length = current_length - charging_retraction_length
				state = DogState.CHARGING
		
		DogState.CHARGING:
			
			#current_length = move_toward(current_length, target_length, retract_speed * delta)
			current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
			
			var extend_dog : bool = false
			#charge_time = min(charge_time + delta, max_charge_time)
			charge_time = charge_time + delta
			if(charge_time >  max_charge_time + max_keep_charging_time):
				extend_dog = true
			
			if Input.is_action_just_released(get_input_action("shoot")):
				extend_dog = true
				
			if extend_dog:
				charge_time = min(charge_time + delta, max_charge_time)
				target_length = max((charge_time / max_charge_time) * max_length, min_extend_length)
				charge_time = 0.0
				state = DogState.EXTENDING
		
		DogState.EXTENDING:
			current_length = move_toward(current_length, target_length, extend_speed * delta)
			check_existing_overlaps()
			
			if current_length > target_length - EXTEND_LENGTH_OFFSET:
				state = DogState.RETRACTING  # auto retract when reached!
		
		DogState.RETRACTING:
			if(current_length > EASE_IN_LENGTH):
				current_length = move_toward(current_length, 0.0, retract_speed * delta)
			else:
				current_length = lerp(current_length, 0.0, 1.0 - exp(-retract_ease_speed * delta))
				if input_buffer:
					input_buffer = false
					target_length = current_length - charging_retraction_length
					state = DogState.CHARGING
				
			if current_length <= 0.0 + RETRACT_LENGTH_OFFSET:
				current_length = 0.0
				state = DogState.IDLE 
				
	
func get_input_action(action: String) -> String:
	return "p" + str(player_index) + "_" + action


func _on_hitbox_body_entered(body: Node2D) -> void:
	# only apply force when actually extending!
	if state != DogState.EXTENDING:
		print("returned")
		return
	
	if body.is_in_group("player"):
		apply_impact(body)
		
		
		
func apply_impact(body):
	# direction away from dog front
	var knock_direction = sign(body.global_position.x - $Front.global_position.x)
	
	# scale knockback with how charged the shot was
	var charge_percent = target_length / max_length  # 0.0 to 1.0
	var force = lerp(KNOCKBACK_MIN_STRENGTH, knockback_stength, charge_percent)
	var force_up = lerp(KNOCKBACK_UP_MIN_STRENGTH, knockback_up, charge_percent)
	
	body.velocity.x = knock_direction * force
	body.velocity.y = -force_up  # launch upward!
	body.is_knocked_back = true
	
func check_existing_overlaps():
	for body in $Front/Hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.is_knocked_back = true
			apply_impact(body)

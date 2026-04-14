extends DogBase

const BASE_MIDDLE_WIDTH = 16.0
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 1.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 3000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.8
const BONUS_DISTANCE = 100
const MAX_HIT_COUNT = 2
const DASH_BONUS = 3.0

var current_length: float = 0.0
var hit_count: int = 0

var start_length : float = 0.0

@export var dog_lunge_length: float = 20.0  # small constant visual lunge
@export var dash_hit_threshold: float = 200.0
@export var min_dash_velocity: float = 20.0
@export var max_dash_velocity: float = 2000.0

# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	start_length = current_length
	target_length = current_length - charging_retraction_length

func on_charging(delta):
	# called EVERY FRAME while charging - lerp toward retracted position
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	
	
func on_release_charge(delta):
	# override target_length set by base class - just a small visual lunge
	target_length = current_length + dog_lunge_length
	# dash the player based on charge time
	var charge_percent = prev_charge_time / max_charge_time
	var player_sprites : Node2D = get_parent().get_parent()  # DogManager -> Sprites -> Player
	var player : Node2D = player_sprites.get_parent()  # DogManager -> Sprites -> Player

	var dash_direction = sign(player_sprites.scale.x)  # whichever way player is facing
	player.velocity.x = dash_direction * lerp(extend_speed * 0.5 * DASH_BONUS, extend_speed + DASH_BONUS, charge_percent)
	player.is_dashing = true
	
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	#check_existing_overlaps()
	current_length = move_toward(current_length, target_length, extend_speed * delta)
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		state = DogState.RETRACTING

func on_retracting(delta):
	if state != DogState.RETRACTING:
		return
		#check_existing_overlaps()
	hit_count = 0
	if current_length > EASE_IN_LENGTH:
		current_length = move_toward(current_length, 0.0, retract_speed * delta)
	else:
		current_length = lerp(current_length, 0.0, 1.0 - exp(-retract_ease_speed * delta))
		if input_buffer:
			input_buffer = false
			on_start_charging(delta)
			state = DogState.CHARGING
	if current_length <= RETRACT_LENGTH_OFFSET:
		current_length = 0.0
		
		state = DogState.IDLE

# ─── visuals ──────────────────────────────────────────────────────────────────

func _process(delta):
	super(delta)  # runs base _process
	update_dog_visuals()

func update_dog_visuals():
	$Middle.scale.x = (BASE_MIDDLE_WIDTH + current_length) / BASE_MIDDLE_WIDTH
	$Front.position.x = $Back.position.x + current_length

# ─── hit ──────────────────────────────────────────────────────────────────────
		
		
	
	
func on_hit(body: CharacterBody2D):
	var player = get_parent().get_parent().get_parent()  # get yourself
	if not player.is_dashing:
		return
	print("my velo ", player.velocity.x)  # your dash velocity
	if abs(player.velocity.x) < dash_hit_threshold:
		return
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return

	hit_count += 1
	var knock_direction = sign(body.global_position.x - player.global_position.x)  # away from YOU
	var velocity_percent = clamp((abs(player.velocity.x) - min_dash_velocity) / (max_dash_velocity - min_dash_velocity), 0.0, 1.0)
	
	apply_knockback(body, knock_direction, velocity_percent)  # body = opponent gets knocked

func apply_knockback(body: CharacterBody2D, knock_direction: float, velocity_percent:float):
	if hit_enemy:
		return
	hit_enemy = true
	
	var force = lerp(300.0, knockback_strength, velocity_percent)
	var force_up = lerp(50.0, knockback_up, 0.5)
	body.velocity.x = knock_direction * force
	body.velocity.y = -force_up
	body.is_knocked_back = true
	hitlag(body)
	
#func check_existing_overlaps():
#	for body in $Front/Hitbox.get_overlapping_bodies():
#		if body.is_in_group("player"):
#			print("found overlapping")
#			on_hit(body)

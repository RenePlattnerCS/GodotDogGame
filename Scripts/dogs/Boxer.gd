extends DogBase

const BASE_MIDDLE_WIDTH = 12.0
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 1.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.5
const BONUS_DISTANCE = 100
const MAX_HIT_COUNT = 2

var current_length: float = 0.0
var hit_count: int = 0

# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	target_length = current_length - charging_retraction_length

func on_charging(delta):
	# called EVERY FRAME while charging - lerp toward retracted position
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	
	
func on_release_charge(delta):
	pass  # target_length already set in base class

# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	current_length = move_toward(current_length, target_length, extend_speed * delta)
	check_existing_overlaps()
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		state = DogState.RETRACTING

func on_retracting(delta):
	if state != DogState.RETRACTING:
		return
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
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return
	if(body.player_index == player_index):
		return
		
	hit_count += 1
	var distance = abs(body.global_position.x - global_position.x)
	var knock_direction = sign(body.global_position.x - $Front.global_position.x)
	var charge_percent = target_length / max_length

	var bonus = 0
	print("distance", distance)
	if charge_percent > CHARGE_PERCENT_BONUS_THRESHOLD and distance > BONUS_DISTANCE \
		or hit_count == MAX_HIT_COUNT:
		bonus = HIGH_CHARGE_KNOCKBACK_BONUS
		print("bonus",bonus)

	# temporarily boost knockback_strength for the bonus, then restore
	var original = knockback_strength
	knockback_strength += bonus
	print("knockback_strength", knockback_strength)
	print("bonus", bonus)
	apply_knockback(body, knock_direction, charge_percent)
	knockback_strength = original

func check_existing_overlaps():
	for body in $Front/Hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			on_hit(body)

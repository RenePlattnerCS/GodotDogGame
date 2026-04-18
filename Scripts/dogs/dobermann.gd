extends DogBase

const BASE_MIDDLE_WIDTH = 3.8
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 4.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.5
const BONUS_DISTANCE = 150
const MAX_HIT_COUNT = 1

var current_length: float = 0.0
var hit_count: int = 0

@onready var shield = $Front/Shield
var player : Node2D

func _ready():
	super()
	START_SCALE = Vector2(0.9, 0.9)
	dont_extend = true
	shield.visible = false
	charging_retraction_length = 4
	player = get_parent().get_parent().get_parent()
	

# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	target_length = current_length - charging_retraction_length
	shield.visible = true
	player.lock_turning_around = true

func on_charging(delta):
	# called EVERY FRAME while charging - lerp toward retracted position
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	
	
func on_release_charge(delta):
	player.lock_turning_around = false
	
	
# ─── shield hit while charging ────────────────────────────────────────────────
func _on_shield_hit(area: Area2D):
	
	if state != DogState.CHARGING:
		return
	# shield got hit while charging → trigger extend
	
	state = DogState.COUNTER
	target_length = max_length
	
func _on_hitbox_body_entered(body : Node2D):
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return
	if(body.player_index == player_index):
		return
	
	if state != DogState.EXTENDING:
		return
	print("hit")	
	hit_count += 1
	var distance = abs(body.global_position.x - global_position.x)
	var knock_direction = sign(body.global_position.x - $Back.global_position.x)
	var charge_percent = target_length / max_length

	var bonus = 0
	print("distance", distance)
	if charge_percent > CHARGE_PERCENT_BONUS_THRESHOLD  or hit_count >= MAX_HIT_COUNT -1 or  distance > BONUS_DISTANCE:
		bonus = HIGH_CHARGE_KNOCKBACK_BONUS
		print("bonus",bonus)

	# temporarily boost knockback_strength for the bonus, then restore
	var original = knockback_strength
	knockback_strength += bonus
	print("knockback_strength", knockback_strength)
	print("bonus", bonus)
	apply_knockback(body, knock_direction, charge_percent)
	knockback_strength = original
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	current_length = move_toward(current_length, target_length, extend_speed * delta)
	check_existing_overlaps()
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		shield.visible = false
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

func on_counter(delta):
	if state != DogState.COUNTER:
		return
	current_length = move_toward(current_length, target_length, extend_speed * delta)
	check_existing_overlaps()
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		shield.visible = false
		state = DogState.RETRACTING
# ─── visuals ──────────────────────────────────────────────────────────────────

func _process(delta):
	super(delta) 
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
	var knock_direction = sign(body.global_position.x - $Back.global_position.x)
	var charge_percent = target_length / max_length
	apply_knockback(body, knock_direction, charge_percent)


func check_existing_overlaps():
	if state != DogState.COUNTER:
		for body in $Front/HitboxRaw.get_overlapping_bodies():
			if body.is_in_group("player"):
				on_hit(body)

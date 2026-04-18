extends DogBase

const BASE_MIDDLE_WIDTH = 3.8
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 4.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.5
const BONUS_DISTANCE = 150
const MAX_HIT_COUNT = 1

const NORMAL_HIT_PENALTY : float = 8.0
const COUNTER_HIT_BONUS : float = 1.9
const COUNTER_HIT_SPEED_BONUS : float = 1.5
const LENGTH_BONUS : float = 100

var current_length: float = 0.0
var hit_count: int = 0

@onready var shield = $Front/Shield
@onready var counter_animation = $counter_animation
@onready var fire = $Front/fire
@onready var back_point = $BackPoint


func _ready():
	super()
	START_SCALE = Vector2(0.8, 0.8)
	dont_extend = true
	shield.visible = false
	charging_retraction_length = 4
	player = get_parent().get_parent().get_parent()
	counter_animation.visible = false
	fire.visible = false
	CAN_HIT_AGAIN_TIME = 0.5
	

# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	target_length = current_length - charging_retraction_length
	shield.visible = true
	player.lock_turning_around = true

func on_charging(delta):
	check_existing_overlaps()
	# called EVERY FRAME while charging - lerp toward retracted position
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	
	
func on_release_charge(delta):
	$Front/HitboxRaw.is_active = true
	
	
# ─── shield hit while charging ────────────────────────────────────────────────
func _on_shield_hit(area: Area2D):
	if state != DogState.CHARGING:
		return
	if not area.is_in_group("dog"):
		return
	print("area ", area)
	if not area.is_active: #check if actually attacking
		return
	# shield got hit while charging → trigger extend
	player.velocity.x = 0
	counter_animation.visible = true
	fire.visible = true
	
	fire.play("fire")
	counter_animation.play("counter")
	counter_animation.animation_finished.connect(func():
		counter_animation.visible = false, CONNECT_ONE_SHOT)
		
	fire.animation_finished.connect(func():
		fire.visible = false , CONNECT_ONE_SHOT)
	
	state = DogState.COUNTER
	target_length = max_length
	
	player.remove_from_group("player")
	
func _on_hitbox_body_entered(body : Node2D):
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return
	if(body.player_index == player_index):
		return
	
	if state != DogState.EXTENDING:
		return
	hit_count += 1
	var distance = abs(body.global_position.x - global_position.x)
	var knock_direction = sign(body.global_position.x - $Back.global_position.x)
	var charge_percent = target_length / max_length

	var bonus = 0
	if charge_percent > CHARGE_PERCENT_BONUS_THRESHOLD  or hit_count >= MAX_HIT_COUNT -1 or  distance > BONUS_DISTANCE:
		bonus = HIGH_CHARGE_KNOCKBACK_BONUS

	# temporarily boost knockback_strength for the bonus, then restore
	var original = knockback_strength
	knockback_strength += bonus
	
	apply_knockback(body, knock_direction, charge_percent)
	knockback_strength = original
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	current_length = move_toward(current_length , target_length + LENGTH_BONUS, extend_speed * delta)
	check_existing_overlaps()
	if current_length >= target_length + LENGTH_BONUS - EXTEND_LENGTH_OFFSET:
		player.lock_turning_around = false
		shield.visible = false
		$Front/HitboxRaw.is_active = false
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
		$Front/HitboxRaw.is_active = false
		state = DogState.IDLE
		
	



func on_counter(delta):
	if state != DogState.COUNTER:
		return
	check_existing_overlaps()
	current_length = move_toward(current_length, target_length, extend_speed * COUNTER_HIT_SPEED_BONUS * delta)
	
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		shield.visible = false
		player.lock_turning_around = false
		player.add_to_group("player")
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
		print("hit_enemy", hit_enemy)
		return
	if(body.player_index == player_index):
		return
	
	hit_count += 1
	var distance = abs(body.global_position.x - global_position.x)
	var knock_direction = sign(body.global_position.x - back_point.global_position.x)
	var charge_percent = target_length / max_length
	var mult = (1 / NORMAL_HIT_PENALTY)
	if(state == DogState.COUNTER):
		mult = COUNTER_HIT_BONUS
	apply_knockback(body, knock_direction, charge_percent, mult)
	hit_enemy = true	


func check_existing_overlaps():
	if state == DogState.COUNTER:
		for body in $Front/Shield/Hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				on_hit(body)
				return
	if state == DogState.EXTENDING:
		for body in $Front/HitboxRaw.get_overlapping_bodies():
			if body.is_in_group("player"):
				on_hit(body)
	
	if state == DogState.CHARGING:
		for area in $Front/Shield/Hitbox.get_overlapping_areas():
			if area.is_in_group("dog"):
				_on_shield_hit(area)
		

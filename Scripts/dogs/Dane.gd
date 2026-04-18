extends DogBase

const BASE_MIDDLE_WIDTH = 14.0
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 1.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.5
const BONUS_DISTANCE = 100
const MAX_HIT_COUNT = 2
const SELF_KNOCKBACK = 1000

const STRENGTH_BONUS = 3000
const SPEED_BONUS = 2

const LENGTH_PENALTY : int = 2


var current_length: float = 0.0
var hit_count: int = 0

var fully_charged: bool = false

var was_overlapping : bool = false
# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	fully_charged = false
	target_length = current_length - charging_retraction_length
	
func on_charging(delta):
	# called EVERY FRAME while charging - lerp toward retracted position
	# auto fire when max charge reached
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))

	if charge_time >= max_charge_time:
		fully_charged = true
	
func on_release_charge(delta):
	var flame = preload("res://Prefabs/flame.tscn").instantiate()
	flame.global_position = $Front.global_position 
	$Front.add_child(flame)
	flame.position = $Front.position + Vector2(20,-20)
	shoot_and_fade(flame)
	check_existing_overlaps()
	$Front/Hitbox.is_active = true

func should_release_charge() -> bool:
	# ignore button release — only fire when fully charged
	return charge_time >= max_charge_time
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	current_length = move_toward(current_length, target_length / LENGTH_PENALTY, extend_speed * SPEED_BONUS * delta)
	#check_existing_overlaps()
	if current_length >= target_length / LENGTH_PENALTY - EXTEND_LENGTH_OFFSET:
		state = DogState.RETRACTING
		$Front/Hitbox.is_active = false

func on_retracting(delta):
	if state != DogState.RETRACTING:
		return
	$Front/Hitbox.is_active = false
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
	

func apply_self_knockback(sign):
	var player = get_parent().get_parent().get_parent()
	var self_knock_direction = sign  # opposite to dash direction
	player.velocity.x = self_knock_direction * (SELF_KNOCKBACK + knockback_strength) / 4  # adjust strength to taste
	player.velocity.y = -100.0  # small upward pop
	player.is_knocked_back = true
	hitlag(player)
	
func on_hit(body: CharacterBody2D):
	
	if not body.is_in_group("player"):
		return

	if(body.player_index == player_index):
		return
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return
	hit_count += 1
	var distance = abs(body.global_position.x - global_position.x)
	var knock_direction = sign(body.global_position.x - global_position.x)
	var charge_percent = target_length / max_length

	var bonus = STRENGTH_BONUS
	# temporarily boost knockback_strength for the bonus, then restore
	var original = knockback_strength
	knockback_strength += bonus
	apply_knockback(body, knock_direction, charge_percent)
	knockback_strength = original
	apply_self_knockback(-1 * knock_direction)

func check_existing_overlaps():
	for body in $Front/Hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			on_hit(body)

func shoot_and_fade(flame: Node):
	# play shoot animation
	flame.play("shoot")
	await flame.animation_finished
	
	# fade out

	var tween = create_tween()
	tween.tween_property(flame, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	flame.queue_free()

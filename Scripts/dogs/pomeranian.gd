extends DogBase

const BASE_MIDDLE_WIDTH = 12.0
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 1.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.5
const BONUS_DISTANCE = 150
const MAX_HIT_COUNT = 4
const CONCECUTIVE_HIT_BONUS = 50
const COMBO_TIME = 0.5


var current_length: float = 0.0
var hit_count: int = 0
@onready var hitbox : Area2D = $Front/PomSprites/Hitbox
@onready var pom_sprite: AnimatedSprite2D = $Front/PomSprites
@onready var bark_animation: AnimatedSprite2D = $Front/BarkAnimation

var last_hit : bool = false

var multiple_hit_bonus : float = 0.0

var combo_timer :float = 0.0
var in_a_combo : bool = false

const MAX_POM_SCALE = 0.7

func _ready():
	super()
	bark_animation.visible = false
	CAN_HIT_AGAIN_TIME = 0.002
	START_SCALE = Vector2(0.7, 0.7) + Vector2(size_bonus, size_bonus)
	player.switch_arms()
	
# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	hitbox.is_active = true
	#target_length = current_length - charging_retraction_length

func on_charging(delta):
	pass
	# called EVERY FRAME while charging - lerp toward retracted position
	#current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	
	
func on_release_charge(delta):
	hitbox.is_active = true
	
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	
	current_length = move_toward(current_length, target_length, extend_speed * delta)
	check_existing_overlaps()
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		hitbox.is_active = false
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
		hitbox.is_active = false
		state = DogState.IDLE

# ─── visuals ──────────────────────────────────────────────────────────────────

func _process(delta):
	if in_a_combo:
		combo_timer += delta
		if combo_timer > COMBO_TIME:
			combo_timer = 0.0
			multiple_hit_bonus = 0.0
			
	
	super(delta)  # runs base _process
	update_dog_visuals()

func update_dog_visuals():
	if state == DogState.EXTENDING:
		# scale up based on how far along the extension we are
		var extend_percent = clamp(current_length / target_length, 0.0, 1.0)
		var s = lerp(START_SCALE.x + size_bonus, START_SCALE.x +size_bonus +  MAX_POM_SCALE, extend_percent)
		pom_sprite.scale = Vector2(s, s)
	elif state == DogState.RETRACTING:
		# shrink back down
		var retract_percent = clamp(current_length / target_length, 0.0, 1.0)
		var s = lerp(START_SCALE.x + size_bonus , START_SCALE.x +size_bonus +  MAX_POM_SCALE, retract_percent)
		pom_sprite.scale = Vector2(s, s)
	else:
		pom_sprite.scale = START_SCALE + Vector2(size_bonus, size_bonus)

# ─── hit ──────────────────────────────────────────────────────────────────────

func on_hit(body: CharacterBody2D):
	in_a_combo = true
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return
	if(body.player_index == player_index):
		return
		
	hit_count += 1
	var distance = abs(body.global_position.x - global_position.x)
	var knock_direction = sign(body.global_position.x - player.global_position.x)
	var charge_percent = clamp(target_length / max_length, 0.0, 1)
	
	
	# temporarily boost knockback_strength for the bonus, then restore
	print("hit count: ", hit_count)
	print("------multiple_hit_bonus-------" , multiple_hit_bonus)
	var original = knockback_strength
	var original_up = knockback_up
	
	knockback_strength += multiple_hit_bonus
	multiple_hit_bonus += CONCECUTIVE_HIT_BONUS
	if hit_count >= MAX_HIT_COUNT or not player.is_on_floor():
		print("max hit")
		bark_animation.visible = true
		bark_animation.play("bark")
		bark_animation.animation_finished.connect(func():
			bark_animation.visible = false, CONNECT_ONE_SHOT)
		var jump_mult = 1 + inverse_lerp(-400.0, -500.0, player.JUMP_VELOCITY)
		print("jump_mult", jump_mult)
		pom_sprite.play("bark") 
		var force = lerp(100.0 * 0.8, knockback_strength * jump_mult * jump_mult, 1)
		var force_up = lerp(50.0, knockback_up * 0.8, 1)
	
		body.velocity.x = knock_direction * force
		body.velocity.y = -force_up
		body.is_knocked_back = true 
		knockback_strength = original  
		return
	var up_bonus = 0
	if(charge_percent < 0.2):
		print("up bonus")
		up_bonus = 5000
	knockback_up += up_bonus
	apply_knockback(body, knock_direction, charge_percent)
	last_hit = false      
	knockback_strength = original
	knockback_up = original_up


func hitlag(body: CharacterBody2D):
	# always apply hitlag regardless of charge percent
	var charge_percent = clamp(prev_charge_time / max_charge_time, 0.0, 1.0)
	var hitlag_duration = lerp(0.05, 0.15, charge_percent)
	hitlag_duration = max(hitlag_duration, 0.05)  # minimum hitlag always guaranteed
	
	body.velocity = Vector2.ZERO
	player.velocity = Vector2.ZERO
	body.set_physics_process(false)
	player.set_physics_process(false)
	set_process(false)

	var flash_time = hitlag_duration / (FLASH_COUNT * 2)
	for i in FLASH_COUNT:
		body.modulate = Color.RED
		await get_tree().create_timer(flash_time, true, false, true).timeout
		body.modulate = Color.WHITE
		await get_tree().create_timer(flash_time, true, false, true).timeout

	body.set_physics_process(true)
	player.set_physics_process(true)
	set_process(true)
	body.modulate = Color.WHITE



func check_existing_overlaps():
	for body in $Front/PomSprites/Hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			on_hit(body)

func cleanup():
	player.switch_arms()
	super()

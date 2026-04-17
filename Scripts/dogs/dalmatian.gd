extends DogBase

@export var arm_scaling = 4

@export var bullet_scene: PackedScene
@export var bullet_count: int = 5
@export var spread_angle: float = 0.4  # radians
@onready var bullet_label: Label = $BulletCounter

@export var open_front_texture: Texture2D
var default_front_texture: Texture2D

const BASE_MIDDLE_WIDTH = 12.0
const BASE_ARM_WIDTH = 128.0
const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 1.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.5
const BONUS_DISTANCE = 150
const MAX_HIT_COUNT = 2

const MAX_LENGTH_DALMATIAN = 40
var current_length: float = 0.0
var hit_count: int = 0

const  MAX_BULLETS = 16
const  RELEOD_TIME = 4
var current_bullets: int = 16
var is_reloading: bool = false



func _ready():
	super()
	charging_retraction_length = 20.0
	START_SCALE = Vector2(0.65, 0.65)
	bullet_scene = preload("res://Prefabs/bullet.tscn")
	default_front_texture = $Front.texture
# ─── charging ─────────────────────────────────────────────────────────────────
func on_start_charging(delta):
	target_length = current_length - charging_retraction_length
	open_front_texture = preload("res://Sprites/Dalmatian/dalmatianFrontOpen.png")
	
func on_charging(delta):
	
	# called EVERY FRAME while charging - lerp toward retracted position
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	
	
func on_release_charge(delta):
	if is_reloading:
		return
		
	$Front.texture = open_front_texture
	var charge_percent = clamp(prev_charge_time / max_charge_time, 0.0, 1.0)
	bullet_count = roundi(lerp(1.0, 8.0, charge_percent))
	bullet_count = min(bullet_count, current_bullets)
	current_bullets -= bullet_count
	update_bullet_display()
	
	var dir = sign(get_parent().get_parent().scale.x)
	
	for i in bullet_count:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = $Front.global_position + Vector2( dir * 25,-4)
		var bknockback_strength = lerp(300.0, knockback_strength * 0.55, charge_percent)
		
		# spread evenly across the arc
		var t = 0.5 if bullet_count == 1 else float(i) / float(bullet_count - 1)
		bullet.setup(dir, lerp(-spread_angle, spread_angle, t), lerp(500.0, bknockback_strength, charge_percent), player_index, (max_length*max_length) / 350, bullet_count)
		
	if current_bullets <= 0:
		start_reload()
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	if state != DogState.EXTENDING:
		return
	current_length = move_toward(current_length, target_length, extend_speed * delta)
	if current_length >= MAX_LENGTH_DALMATIAN - EXTEND_LENGTH_OFFSET:
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
		$Front.texture = default_front_texture
		current_length = 0.0
		state = DogState.IDLE
		
	

# ─── visuals ──────────────────────────────────────────────────────────────────

func _process(delta):
	super(delta)  # runs base _process
	scale = START_SCALE
	update_dog_visuals()

func update_dog_visuals():
	$Middle.scale.x = (BASE_MIDDLE_WIDTH + current_length) / BASE_MIDDLE_WIDTH
	$Front.position.x = $Back.position.x + current_length
	
	if state == DogState.EXTENDING or state == DogState.RETRACTING:
		$Arm.scale.x = (BASE_ARM_WIDTH + current_length) / BASE_ARM_WIDTH
	else:
		$Arm.scale.x = (BASE_ARM_WIDTH + current_length * arm_scaling) / BASE_ARM_WIDTH

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
	
	
func start_reload():
	is_reloading = true
	update_bullet_display()
	# play reload animation here
	print("reloading retract_speed! " , retract_speed)
	print("time ! " , RELEOD_TIME * (300/retract_speed ))
	await get_tree().create_timer(RELEOD_TIME * (300/retract_speed )).timeout  # reload time
	current_bullets = MAX_BULLETS
	is_reloading = false
	update_bullet_display()
	
func update_bullet_display():
	if is_reloading:
		bullet_label.text = "↺"  # or "RELOAD"
	else:
		bullet_label.text = str(current_bullets)

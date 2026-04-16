class_name DogBase
extends Node2D

@export var stats: DogStats

@export_group("Attacking")
@export var max_charge_time: float = 2.0
@export var max_keep_charging_time: float = 3.0
@export var max_length: float = 170.0
@export var extend_speed: float = 700.0
@export var retract_speed: float = 300.0
@export var retract_ease_speed: float = 5.0
@export var min_extend_length: float = 30.0
@export var charging_retraction_length: float = 15.0
@export var buffer_time: float = 0.4
@export var knockback_up: float = 600.0
@export var knockback_strength: float = 4000.0
@export var charge_speed_multiplier: float = 1.0
@export var size_bonus: float = 0.0
@export var  START_SCALE : Vector2 = Vector2(1.0, 1.0)

@export_group("Blinking")
@export var max_blink_speed: float = 10.0
@export var min_blink_speed: float = 0.5

const HITLAG_THREASHOLD = 0.50
const FLASH_COUNT = 3
var CAN_HIT_AGAIN_TIME = 0.1

var player_index: int = -69
var charge_time: float = 0.0
var over_charge_time: float = 0.0
var prev_charge_time: float = 0.0
var blink_timer: float = 0.0
var hit_again_timer: float = 0.0
var hit_enemy: bool = false
var target_length: float = 0.0
var input_buffer: bool = false
var buffer_timer: float = 0.0

enum DogState { IDLE, CHARGING, EXTENDING, RETRACTING }
var state: DogState = DogState.IDLE


func _ready():
	player_index = get_parent().get_parent().get_parent().player_index
	if player_index == -1:
		print("couldn't find player index")
	apply_stats()

func _process(delta):
	process_input_buffer(delta)
	process_charge_state(delta)
	on_extending(delta)
	on_retracting(delta)
	update_charge_visuals(delta)
	update_hit_timer(delta)

# ─── input ────────────────────────────────────────────────────────────────────

func process_input_buffer(delta):
	if Input.is_action_just_pressed(get_input_action("shoot")):
		input_buffer = true
		buffer_timer = buffer_time
	if input_buffer:
		buffer_timer -= delta
		if buffer_timer <= 0.0:
			input_buffer = false

func get_input_action(action: String) -> String:
	return "p" + str(player_index) + "_" + action

# ─── state machine ────────────────────────────────────────────────────────────

func process_charge_state(delta):
	match state:
		DogState.IDLE:
			if input_buffer:
				input_buffer = false
				on_start_charging(delta)
				state = DogState.CHARGING

		DogState.CHARGING:
			charge_time += delta * charge_speed_multiplier
			over_charge_time += delta
			on_charging(delta)

			var should_release = should_release_charge()

			if should_release:
				charge_time = min(charge_time, max_charge_time)
				target_length = max((charge_time / max_charge_time) * max_length, min_extend_length)
				prev_charge_time = charge_time
				charge_time = 0.0
				over_charge_time = 0.0
				on_release_charge(delta)
				state = DogState.EXTENDING


func should_release_charge() -> bool:
	return over_charge_time > max_keep_charging_time \
		or Input.is_action_just_released(get_input_action("shoot"))
# ─── virtual methods (override in each dog) ───────────────────────────────────

func on_start_charging(delta):
	pass  # e.g. boxer pulls back, rocket aims
	
func on_charging(delta):
	pass

func on_release_charge(delta):
	pass  # e.g. boxer lunges, rocket fires

func on_extending(delta):
	pass  # called every frame while EXTENDING

func on_retracting(delta):
	pass  # called every frame while RETRACTING

func on_hit(body: CharacterBody2D):
	pass  # override to define what hitting an enemy does

# ─── hitbox ───────────────────────────────────────────────────────────────────

func _on_hitbox_body_entered(body: Node2D) -> void:
	if state != DogState.EXTENDING:
		return
	if body.is_in_group("player"):
		on_hit(body)

# ─── knockback helper (dogs can call this, or override entirely) ──────────────

func apply_knockback(body: CharacterBody2D, knock_direction: float, charge_percent: float):
	if hit_enemy:
		return
	hit_enemy = true
	var force = lerp(100.0 * 0.8, knockback_strength * 0.8, charge_percent)
	var force_up = lerp(50.0, knockback_up * 0.8, charge_percent)

	body.velocity.x = knock_direction * force
	body.velocity.y = -force_up
	body.is_knocked_back = true
	hitlag(body)

# ─── hitlag ───────────────────────────────────────────────────────────────────

func hitlag(body: CharacterBody2D):
	var charge_percent = clamp(prev_charge_time / max_charge_time, 0.0, 1.0)
	if charge_percent > HITLAG_THREASHOLD:
		var hitlag_duration = lerp(0.05, 0.15, charge_percent)
		var flash_time = hitlag_duration / (FLASH_COUNT * 2)
		Engine.time_scale = 0.08
		for i in FLASH_COUNT:
			body.modulate = Color.RED
			await get_tree().create_timer(flash_time, true, false, true).timeout
			body.modulate = Color.WHITE
			await get_tree().create_timer(flash_time, true, false, true).timeout
		Engine.time_scale = 1.0
		body.modulate = Color.WHITE

# ─── hit cooldown ─────────────────────────────────────────────────────────────

func update_hit_timer(delta):
	if hit_enemy:
		hit_again_timer += delta
		if hit_again_timer > CAN_HIT_AGAIN_TIME:
			hit_again_timer = 0.0
			hit_enemy = false

# ─── charge visuals ───────────────────────────────────────────────────────────

func update_charge_visuals(delta):
	if state == DogState.CHARGING:
		var charge_percent = clamp(charge_time / max_charge_time, 0.0, 1.0)
		var blink_speed = lerp(min_blink_speed, max_blink_speed, charge_percent)
		blink_timer += delta * blink_speed
		var blink = (sin(blink_timer * TAU) + 1.0) / 2.0
		modulate = lerp(Color.ORANGE_RED, Color.LIGHT_YELLOW, blink)
	else:
		blink_timer = 0.0
		modulate = Color.WHITE


func apply_stats():
	# override in each dog to read from stats
	max_length = stats.max_length
	extend_speed = stats.extend_speed
	knockback_strength = stats.knockback_strength
	charge_speed_multiplier = stats.charge_speed_multiplier
	size_bonus = stats.size_bonus
	print("........apply stats size bonus...........", size_bonus)
	scale = START_SCALE +	Vector2(size_bonus,size_bonus)
	
	
	

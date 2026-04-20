extends DogBase

const EXTEND_LENGTH_OFFSET = 20.0
const RETRACT_LENGTH_OFFSET = 1.0
const EASE_IN_LENGTH = 20.0
const HIGH_CHARGE_KNOCKBACK_BONUS = 2000
const CHARGE_PERCENT_BONUS_THRESHOLD = 0.8
const BONUS_DISTANCE = 100
const MAX_HIT_COUNT = 3
const MAX_ROCKET_LENGTH = 1200

var MAX_SCALE : Vector2 = Vector2(1, 1)

var current_length: float = 0.0
var hit_count: int = 0

var shoot_speed : float = 1.0
var launch_position
var curr_scale : Vector2 = Vector2(0.7, 0.7)
const KNOCKBACK_MULT = 1.4

@onready var front : Sprite2D = $Front  
@onready var player_sprites = get_parent().get_parent()

var saved_start_position : Transform2D
var front_rest_position: Vector2  # add this as a var
var fire_direction: int = 1
var bullet_scale: Vector2 = Vector2(0.7, 0.7)

var retract_length : float = 0.0
#----------
@export var missile_scene: PackedScene


#--------
func _ready():
	super()
	START_SCALE = Vector2(0.7,0.7) 
	front_rest_position = front.position
# ─── charging ─────────────────────────────────────────────────────────────────

func on_start_charging(delta):
	curr_scale = START_SCALE + Vector2(size_bonus, size_bonus)
	scale = curr_scale
	target_length = current_length - charging_retraction_length
	shoot_speed = 1.0
	

func on_charging(delta):
	# just lerp the front back slightly during charge windup
	current_length = lerp(current_length, target_length, 1.0 - exp(-retract_ease_speed * delta))
	var charge_percent = clamp(charge_time / max_charge_time, 0.0, 1.0)
	var squared_size_bonus = (1+size_bonus) * (1+size_bonus)
	squared_size_bonus -= 1
	curr_scale = lerp(START_SCALE + Vector2(squared_size_bonus, squared_size_bonus), MAX_SCALE + Vector2(squared_size_bonus * 2, squared_size_bonus * 2), charge_percent)
	scale = curr_scale  # ✅ grow the dog while charging


func on_release_charge(delta):
	var charge_percent = clamp(prev_charge_time / max_charge_time, 0.0, 1.0)
	var initial_speed = lerp(40.0, 300.0, charge_percent)
	var missile_target_length = MAX_ROCKET_LENGTH
	if retract_speed > 300:
		missile_target_length -= 200

	# hide front
	front.visible = false

	# spawn missile at front's current world position
	var missile = missile_scene.instantiate()
	get_tree().current_scene.add_child(missile)
	missile.setup(
		$Back.global_position,
		sign(player_sprites.scale.x),
		initial_speed,
		curr_scale,
		missile_target_length,
		player_index,
		knockback_strength,
		knockback_up,
		player,
		charge_percent
	)
	missile.tree_exited.connect(_on_missile_done)  # called when missile queue_free's

	# reset state immediately
	current_length = 0.0
	state = DogState.RETRACTING

func _on_missile_done():
	front.visible = true
	curr_scale = START_SCALE + Vector2(size_bonus, size_bonus)
	scale = curr_scale
	state = DogState.IDLE
# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	pass
		

func on_retracting(delta):
	pass

		

# ─── visuals ──────────────────────────────────────────────────────────────────

		

func update_dog_visuals():
	pass


func cleanup():
	# find and free any live missiles
	for node in get_tree().current_scene.get_children():
		if node is Missile:
			if node.player_index == player_index:
				node.queue_free()
	front.visible = true
	Engine.time_scale = 1.0

	

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
	front.scale = curr_scale
	var charge_percent = clamp(prev_charge_time / max_charge_time, 0.0, 1.0)
	shoot_speed = lerp(40 , 500, charge_percent)
	target_length = MAX_ROCKET_LENGTH
	if(retract_speed > 300):
		target_length -= 200
	front.get_node("Hitbox").is_active = true
	bullet_scale = curr_scale  
	

	current_length = 0
	fire_direction = sign(player_sprites.scale.x)

	var saved_pos = $Back.global_position
	launch_position = saved_pos
	front.get_parent().remove_child(front)
	get_tree().current_scene.add_child(front)
	front.global_position = saved_pos
	#front.scale = Vector2(0.7, 0.7)
	front.scale.x = front.scale.x * fire_direction
	front.rotation = 0.0  # reset rotation after detach

# ─── extending & retracting ───────────────────────────────────────────────────

func on_extending(delta):
	
	if state != DogState.EXTENDING:
		return
	# only move the Front node, no middle stretching
	current_length = move_toward(current_length, target_length, shoot_speed * delta)
	shoot_speed += delta * shoot_speed
	#check_existing_overlaps()
	if current_length >= target_length - EXTEND_LENGTH_OFFSET:
		retract_length = current_length
		state = DogState.RETRACTING
		front.get_node("Hitbox").is_active = false
		

func on_retracting(delta):
	if state != DogState.RETRACTING:
		return
	
	front.get_node("Hitbox").is_active = false
	retract_length -= (retract_speed * delta) * 4
	

	if retract_length <= RETRACT_LENGTH_OFFSET:
		restore_front_missile()
		state = DogState.IDLE

		

# ─── visuals ──────────────────────────────────────────────────────────────────
func restore_front_missile():
	curr_scale = START_SCALE + Vector2(size_bonus, size_bonus)
	#scale = curr_scale
	hit_count = 0
	
	current_length = 0.0
	
	if front.get_parent() != self:
		front.reparent(self)
		front.position = front_rest_position
		front.rotation = 0.0

		front.scale = Vector2(1.0, 1.0)
		curr_scale = START_SCALE + Vector2(size_bonus, size_bonus)  # reset dog scale
		scale = curr_scale
		
func _process(delta):
	super(delta)
	
	update_dog_visuals()

func update_dog_visuals():
	if front.get_parent() != self:
		front.global_position.x = launch_position.x + current_length * fire_direction

# ─── hit ──────────────────────────────────────────────────────────────────────

func on_hit(body: Node2D ):
	if not body.is_in_group("player"):
		return
	if(body.player_index == player_index):
		return
		
	if state != DogState.EXTENDING:
		return
		
	if hit_enemy or hit_count > MAX_HIT_COUNT:
		return
	hit_count += 1
	var knock_direction = sign(body.global_position.x - front.global_position.x)
	var charge_percent = clamp(prev_charge_time / max_charge_time, 0.3, 1.0)
	var mult = KNOCKBACK_MULT
	if(knockback_strength > 2000):
		mult = lerp(KNOCKBACK_MULT, 1.0 , charge_percent)
	print("-------------mult--------", mult)
	apply_knockback(body, knock_direction, charge_percent,mult)

func check_existing_overlaps():
	for body in front.Hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			on_hit(body)

func cleanup():
	if front.get_parent() != self:
		front.queue_free()
	Engine.time_scale = 1.0

	

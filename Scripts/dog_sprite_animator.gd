extends Sprite2D

@export var float_speed: float = 2.0
@export var float_height: float = 20.0
@export var spin_speed: float = 1.5

var origin_y: float = -40.0

var time: float = 0.0
var players_in_range: Array = []

var dog_type

func _ready():
	#origin_y = position.y
	call_deferred("_setup_area")

func _setup_area():
	
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	area.collision_layer = 8 
	area.collision_mask = 0  
	area.set_collision_mask_value(2, true)
	
	circle.radius = 30.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	
func _process(delta: float) -> void:
	time += delta
	
	# smooth up/down with sine
	position.y = origin_y + sin(time * float_speed) * float_height
	
	# 3D spin via scale.x (simulates Y-axis rotation)
	scale.x = cos(time * spin_speed)
	
	#--------------
	# check pickup input for each player in range
	for player in players_in_range:
		var idx = player.player_index
		if Input.is_action_just_pressed("p" + str(idx) + "_pickup"):
			EventSystem.dog_picked_up.emit(player, dog_type)
			queue_free()

func _on_body_entered(body):
	print(" entered ", body)
	if body.is_in_group("player"):
		print("player entered")
		players_in_range.append(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		players_in_range.erase(body)

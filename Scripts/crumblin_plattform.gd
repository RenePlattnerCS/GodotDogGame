extends RigidBody2D

@export var shake_duration: float = 3.5
var is_crumbling: bool = false

func _ready():
	freeze = true  # acts like StaticBody2D until crumble!
	

func crumble():
	if is_crumbling:
		return
	is_crumbling = true
	
	# shake warning
	var original_pos = position
	var shake_timer = 0.0
	while shake_timer < shake_duration:
		position.x = original_pos.x + randf_range(-1.0, 1.0)
		shake_timer += get_process_delta_time()
		await get_tree().process_frame
	position = original_pos
	
	# just unfreeze — it falls automatically!
	freeze = false
	
	# destroy after falling
	await get_tree().create_timer(2.0).timeout
	queue_free()

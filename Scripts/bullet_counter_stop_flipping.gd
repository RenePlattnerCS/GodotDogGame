extends Label

var start_position : Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_position = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	scale.x = get_parent().get_parent().get_parent().scale.x
	
	if(scale.x < 0):
		position = start_position + Vector2(20,0)
	else:
		position = start_position

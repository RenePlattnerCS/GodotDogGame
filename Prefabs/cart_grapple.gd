extends AnimatedSprite2D


@export var rope_length: float = 163.0

const GRAPPLER_OFFSET = 33
# the direction the rope extends (normalized vector)
func _process(delta: float) -> void:
	update_rope()
	
func update_rope():
	$Rope2.region_enabled = true
	# grow the region instead of the scale
	$Rope2.region_rect = Rect2(0, 0, 32, rope_length)
	$Grappler.position.y = rope_length - GRAPPLER_OFFSET
	
	

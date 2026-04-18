extends Area2D

var direction: float = 1.0
var speed: float = 800.0
var angle: float = 0.0  # spread angle in radians
var knockback_strength: float = 100.0
var player_index: int = -1




func _physics_process(delta):
	var velocity = Vector2(cos(angle) * direction, sin(angle)) * speed
	global_position += velocity * delta


func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	if body.player_index == player_index:
		return
	
	var knock_direction = sign(body.global_position.x - global_position.x)
	body.velocity.x = direction * knockback_strength
	body.velocity.y = -400.0
	body.is_knocked_back = true
	queue_free()
	
	
func setup(p_direction: float, p_angle: float, p_knockback: float, p_player_index: int, p_length : float, bullet_count: int):
	direction = p_direction
	angle = p_angle
	knockback_strength = p_knockback
	player_index = p_player_index
	# rotate sprite to match travel direction
	$Sprite2D.rotation = angle if direction > 0 else PI - angle
	
	if direction < 0:
		$Sprite2D.scale.y *= -1
		
	var flight_time = p_length / speed
	if bullet_count > 1:
		get_tree().create_timer(flight_time).timeout.connect(queue_free)
	else:
		get_tree().create_timer(flight_time * 10).timeout.connect(queue_free)

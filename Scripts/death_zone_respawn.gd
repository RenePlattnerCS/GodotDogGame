extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if(body.is_in_group("player")):
		EventSystem.player_died.emit()
		body.velocity = Vector2(0,0)	
		if(body.player_index == 1):
			$choose_screen.show_death_screen(body)
		if(body.player_index == 2):
			$choose_screen2.show_death_screen(body)

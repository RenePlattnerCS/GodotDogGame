extends Area2D

@export var spawn_point_p1: Node2D 
@export var spawn_point_p2: Node2D 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Loser screen".visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func respawn(player):
	disable_player(player)
	show_death_screen()
	
func disable_player(player):
	player.visible = false
	player.set_process(false)        # disables _process
	player.set_physics_process(false) # disables _physics_process
	
func show_death_screen():
	$"Loser screen".visible = true
	$MarginContainer/CenterContainer/VBoxContainer/HBoxContainer/Button.grab_focus()
	
func _on_body_entered(body: Node2D) -> void:
	
	if(not spawn_point_p1 or not spawn_point_p2):
		print("missing spawn point")
		return
	if(body.is_in_group("player")):
		body.velocity = Vector2(0,0)
		if(body.player_index == 1):
			body.global_position = spawn_point_p1.position
		if(body.player_index == 2):
			body.global_position = spawn_point_p2.position
			
		respawn(body)
	pass # Replace with function body.

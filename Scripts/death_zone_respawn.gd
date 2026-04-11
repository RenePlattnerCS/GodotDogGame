extends Area2D

@export var spawn_point_p1: Node2D 
@export var spawn_point_p2: Node2D 

@export var button1: Button
@export var button2: Button

var focused_button_index: int = 0
var buttons: Array = []
var controlling_player: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Loser screen".visible = false
	buttons = [button1, button2]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not $"Loser screen".visible or not buttons[0] or not buttons[1]:
		return
		
	var left = "p" + str(controlling_player) + "_ui_left"
	var right = "p" + str(controlling_player) + "_ui_right"
	var accept = "p" + str(controlling_player) + "_ui_accept"
	
	if Input.is_action_just_pressed(left):
		focused_button_index = max(0, focused_button_index - 1)
		update_focus()
	
	if Input.is_action_just_pressed(right):
		focused_button_index = min(buttons.size() - 1, focused_button_index + 1)
		update_focus()
	
	if Input.is_action_just_pressed(accept):
		buttons[focused_button_index].emit_signal("pressed")

func die(player):
	disable_player(player)
	controlling_player = player.player_index
	show_death_screen()
	focused_button_index = 0
	
func disable_player(player):
	player.visible = false
	player.set_process(false)        # disables _process
	player.set_physics_process(false) # disables _physics_process
	
func show_death_screen():
	$"Loser screen".visible = true
	
	
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
			
		die(body)
	pass # Replace with function body.

func update_focus():
	for i in buttons.size():
		if i == focused_button_index:
			buttons[i].grab_focus()
			set_button_border(buttons[i], Color.RED)
		else:
			set_button_border(buttons[i], Color.WHITE)

func set_button_border(button: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_color = color
	style.bg_color = Color(0, 0, 0, 0)
	button.add_theme_stylebox_override("normal", style)
	
func hide_death_screen():
	$"Loser screen".visible = false

func respawn(player: CharacterBody2D):
	hide_death_screen()
	player.visible = true
	player.set_process(true)
	player.set_physics_process(true)
	player.velocity = Vector2.ZERO
	player.is_knocked_back = false

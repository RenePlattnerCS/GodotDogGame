extends CanvasLayer

@export var button1: Button
@export var button2: Button
@export var controlled_player: CharacterBody2D
@export var UpgradeManager: Node2D


var focused_button_index: int = 0
var buttons: Array = []
var offered_upgrades: Array = []

var left :String = ""
var right :String = ""
var accept :String = ""
var prev_ui_direction: float = 0.0
	
func _ready() -> void:
	visible = false
	buttons = [button1, button2]
	button1.pressed.connect(_on_button1_pressed) 
	button2.pressed.connect(_on_button2_pressed)
	
	# disable godot's built in controller navigation
	button1.focus_neighbor_left = button1.get_path()
	button1.focus_neighbor_right = button1.get_path()
	button1.focus_neighbor_top = button1.get_path()
	button1.focus_neighbor_bottom = button1.get_path()
	button2.focus_neighbor_left = button2.get_path()
	button2.focus_neighbor_right = button2.get_path()
	button2.focus_neighbor_top = button2.get_path()
	button2.focus_neighbor_bottom = button2.get_path()
	
	if not controlled_player:
		print("no player assigned!")
		return
	left = "p" + str(controlled_player.player_index) + "_ui_left"
	right = "p" + str(controlled_player.player_index) + "_ui_right"
	accept = "p" + str(controlled_player.player_index) + "_ui_accept"

func _process(delta: float) -> void:
	if not visible:
		return

	var ui_dir = Input.get_axis(left, right)
	var just_moved = abs(ui_dir) > 0.5 and abs(prev_ui_direction) <= 0.5
	var just_moved_digital = Input.is_action_just_pressed(left) or Input.is_action_just_pressed(right)
	if just_moved or just_moved_digital:
		if ui_dir < 0 or Input.is_action_just_pressed(left):
			focused_button_index = max(0, focused_button_index - 1)
		else:
			focused_button_index = min(buttons.size() - 1, focused_button_index + 1)
		buttons[focused_button_index].grab_focus()
	
	prev_ui_direction = ui_dir
	
	if Input.is_action_just_pressed(accept):
		if focused_button_index == 0:
			_on_button1_pressed()
		else:
			_on_button2_pressed()

func show_death_screen(player):
	player.disable_player()
	if not UpgradeManager:
		print("no upgrade manager assigned")
		return
	offered_upgrades = UpgradeManager.get_random_upgrades(2)
	init_button(buttons[0], offered_upgrades[0])
	init_button(buttons[1], offered_upgrades[1])
	focused_button_index = 0
	visible = true
	button1.grab_focus()  # focus first button on show

func _on_button1_pressed():
	if focused_button_index != 0:
		return  # ignore if not focused
	offered_upgrades[0].apply(controlled_player)
	hide_death_screen()
	controlled_player.respawn()
	EventSystem.player_respawned.emit()

func _on_button2_pressed():
	if focused_button_index != 1:
		return  # ignore if not focused
	offered_upgrades[1].apply(controlled_player)
	hide_death_screen()
	controlled_player.respawn()
	EventSystem.player_respawned.emit()
	
func init_button(button: Button, upgrade):
	button.icon = upgrade.icon
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var label = button.get_node("Label")
	label.text = upgrade.name
	label.add_theme_color_override("font_color", upgrade.button_text_color)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", upgrade.button_text_border_color)
	label.add_theme_constant_override("outline_size", 8)

func hide_death_screen():
	visible = false
	

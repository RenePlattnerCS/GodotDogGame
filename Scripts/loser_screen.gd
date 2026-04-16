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
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	visible = false
	buttons = [button1, button2]
	button1.pressed.connect(_on_button1_pressed) 
	button2.pressed.connect(_on_button2_pressed) 
	
	if(not controlled_player):
		print("no plaxer assigned!")
		return
	left = "p" + str(controlled_player.player_index) + "_ui_left"
	right = "p" + str(controlled_player.player_index) + "_ui_right"
	accept = "p" + str(controlled_player.player_index) + "_ui_accept"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not visible or not buttons[0] or not buttons[1]:
		return
	
	if Input.is_action_just_pressed(left):
		focused_button_index = max(0, focused_button_index - 1)
		update_focus()
	
	if Input.is_action_just_pressed(right):
		focused_button_index = min(buttons.size() - 1, focused_button_index + 1)
		update_focus()
	
	if Input.is_action_just_pressed(accept):
		buttons[focused_button_index].pressed.emit()	
	

	
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
	update_focus()

func update_focus():
	for i in buttons.size():
		if i == focused_button_index:
			buttons[i].grab_focus()
			set_button_border(buttons[i], Color.RED)
		else:
			set_button_border(buttons[i], Color.WHITE)

func init_button(button : Button, upgrade):
	button.icon = upgrade.icon
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# text 
	var label = button.get_node("Label")
	
	label.text = upgrade.name
	
	label.add_theme_color_override("font_color", upgrade.button_text_color)
	
	# outline color and size
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", upgrade.button_text_border_color)
	label.add_theme_constant_override("outline_size", 8)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


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
	visible = false

func _on_button1_pressed():
	print("button1 pressed for: ", controlled_player) 
	offered_upgrades[0].apply(controlled_player)
	hide_death_screen()
	controlled_player.respawn()
	EventSystem.player_respawned.emit()

func _on_button2_pressed():
	print("button2 pressed for " , controlled_player)
	offered_upgrades[1].apply(controlled_player)
	hide_death_screen()
	controlled_player.respawn()
	EventSystem.player_respawned.emit()

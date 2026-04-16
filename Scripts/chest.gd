extends AnimatedSprite2D

var dog_preview_sprite: Sprite2D

enum DogType { BOXER, DACHSHUND , DANE, GREYHOUND}
var current_dog_type: DogType

const DOG_SPRITES = {
	DogType.BOXER: preload("res://Sprites/DogSprites/boxer.png"),
	DogType.DACHSHUND: preload("res://Sprites/DogSprites/Dachshund.png"),
	DogType.DANE: preload("res://Sprites/DogSprites/dane.png"),
	DogType.GREYHOUND : preload("res://Sprites/DogSprites/greyHound.png")
}



func _ready():
	animation_finished.connect(_on_animation_finished)
	# connect to the signal that fires when someone dies
	EventSystem.player_died.connect(_on_player_died)
	EventSystem.player_respawned.connect(_on_player_respawn)
	
func _on_player_died():
	if(dog_preview_sprite):
		dog_preview_sprite.queue_free()
		dog_preview_sprite = null
	modulate = Color.WHITE
	play("open")
	# pick random dog for next round
	var all_types = DogType.values()
	#current_dog_type = all_types[randi() % all_types.size()]
	current_dog_type = DogType.GREYHOUND
	show_dog_preview(current_dog_type)

func _on_player_respawn():
	modulate = Color(0.3, 0.3, 0.3)
	play("close")
	#remove_dog_preview()
	
func _on_animation_finished():
	if animation == "close":
		play("idle")


	
	

	
func show_dog_preview(dog_type: DogType):
	if dog_preview_sprite:
		dog_preview_sprite.queue_free()
	dog_preview_sprite = Sprite2D.new()
	dog_preview_sprite.texture = DOG_SPRITES[dog_type]
	
	dog_preview_sprite.set_script(preload("res://Scripts/dog_sprite_animator.gd"))
	dog_preview_sprite.dog_type = dog_type 
	dog_preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var chest = get_tree().get_first_node_in_group("chest")
	dog_preview_sprite.transform = chest.transform
	#add_child(dog_preview_sprite)
	#dog_preview_sprite.position = Vector2(-5, -80)
	get_parent().add_child(dog_preview_sprite)  # ← sibling, not child
	dog_preview_sprite.global_position = global_position + Vector2(0, 80)

func remove_dog_preview():
	if dog_preview_sprite:
		dog_preview_sprite.queue_free()
		dog_preview_sprite = null

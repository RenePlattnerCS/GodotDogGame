class_name DogManager
extends Node2D

@export var default_dog_scene: PackedScene

enum DogType { BOXER, DACHSHUND }


var current_dog: DogBase
var player_index: int = -1

const DOG_SCENES = {
	DogType.BOXER: preload("res://Prefabs/boxer.tscn"),
	DogType.DACHSHUND: preload("res://Prefabs/Dachshund.tscn"),
}



func _ready():
	current_dog = $Boxer
	EventSystem.dog_picked_up.connect(_on_dog_picked_up)
	player_index = get_parent().get_parent().player_index
	
func _process(delta: float) -> void:
	pass
	
	
	
func swap_dog(dog_type: DogType):
	var old_stats = current_dog.stats
	if current_dog:
		current_dog.queue_free()
		current_dog = null 
	print(old_stats)
	current_dog = DOG_SCENES[dog_type].instantiate()
	#"res://Dog_stats/dog_stats.tres"
	
	current_dog.stats = old_stats
	add_child(current_dog)
	current_dog.apply_stats()

# ─── stat upgrades ────────────────────────────────────────────────────────────

func increase_knockback(added_strength: int):
	current_dog.stats.knockback_strength += added_strength
	current_dog.apply_stats()

func decrease_charge_time():
	current_dog.stats.charge_speed_multiplier *= 2
	current_dog.apply_stats()

func increase_length(length: int, extend_speed: int, retract_speed: int):
	current_dog.stats.max_length += length
	current_dog.stats.extend_speed += extend_speed
	current_dog.stats.retract_speed += retract_speed
	current_dog.apply_stats()
#------------------
func _on_dog_picked_up(player, dog_type):
	print(player_index)
	if player.player_index == get_parent().get_parent().player_index:
		swap_dog(dog_type)
	

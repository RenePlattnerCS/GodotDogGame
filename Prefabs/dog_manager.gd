class_name DogManager
extends Node2D

@export var default_dog_scene: PackedScene

enum DogType { BOXER, DACHSHUND, DANE , GREYHOUND, DALMATIAN, DOBERMANN, POMERANIAN}


var current_dog: DogBase
var player_index: int = -1

const DOG_SCENES = {
	DogType.BOXER: preload("res://Prefabs/boxer.tscn"),
	DogType.DACHSHUND: preload("res://Prefabs/Dachshund.tscn"),
	DogType.DANE: preload("res://Prefabs/dane.tscn"),
	DogType.GREYHOUND: preload("res://Prefabs/greyhound.tscn"),
	DogType.DALMATIAN: preload("res://Prefabs/dalmatian.tscn"),
	DogType.DOBERMANN: preload("res://Prefabs/dobermann.tscn"),
	DogType.POMERANIAN: preload("res://Prefabs/pomeranian.tscn")
,}



func _ready():
	current_dog = $Boxer
	EventSystem.dog_picked_up.connect(_on_dog_picked_up)
	player_index = get_parent().get_parent().player_index
	
func _process(delta: float) -> void:
	pass
	
	
	
func swap_dog(dog_type: DogType):
	var old_stats = current_dog.stats
	if current_dog:
		current_dog.cleanup()
		current_dog.queue_free()
		current_dog = null 
	current_dog = DOG_SCENES[dog_type].instantiate()
	
	current_dog.stats = old_stats
	add_child(current_dog)
	current_dog.apply_stats()

# ─── stat upgrades ────────────────────────────────────────────────────────────

func increase_knockback(added_strength: int):
	current_dog.stats.knockback_strength += added_strength
	current_dog.apply_stats()

func decrease_charge_time(mult : float):
	current_dog.stats.charge_speed_multiplier *= mult
	current_dog.apply_stats()

func increase_length(length: int, extend_speed: int):
	current_dog.stats.max_length += length
	current_dog.stats.extend_speed += extend_speed
	current_dog.apply_stats()
	
func decrease_retraction(speed_retraction_bonus):
	print("decrease retraction")
	current_dog.stats.retract_speed += speed_retraction_bonus
	current_dog.apply_stats()
#------------------
func _on_dog_picked_up(player, dog_type):
	print(player_index)
	if player.player_index == get_parent().get_parent().player_index:
		swap_dog(dog_type)
		
func increase_size(size_bonus):
	current_dog.stats.size_bonus += size_bonus
	current_dog.apply_stats()
	
	

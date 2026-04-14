extends Node2D


var box : RigidBody2D 

var timer = 0.0
var one_shot = false
var trng = 0

func _ready() -> void:
	box = $CargoDropBox
	box.freeze = true
	trng = randf_range(-10.0, 30.0)
	
func _process(delta: float) -> void:
	timer += delta
	if timer > 50 + trng and not one_shot:
		release_grapple()
		one_shot = true
	pass
	
func release_grapple():
	$GrapplerFront.play("release")
	$GrappleBack.play("release")
	
	
	# remember world position before reparenting
	var world_pos = box.global_position
	
	# detach from grapple and add to level so it falls independently
	box.get_parent().remove_child(box)
	get_parent().add_child(box)
	
	# restore world position (reparenting resets it)
	box.global_position = world_pos
	
	# unfreeze so gravity takes over
	box.freeze = false

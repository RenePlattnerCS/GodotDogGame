# hitbox.gd
extends Area2D

var is_active: bool = false:
	get:
		return is_active
	set(value):
		is_active = value

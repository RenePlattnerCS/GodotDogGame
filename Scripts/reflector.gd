extends Node2D

@onready var reflector = $reflect
@onready var dust = $Dashdust
@onready var hitbox = $reflect/ReflectArea
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dust.visible = false
	reflector.visible = false
	hitbox.monitorable = false


func _process(delta: float) -> void:
	pass

func start_dash_reflect():
	dust.visible = true
	reflector.visible = true
	hitbox.monitorable = true
	dust.play("dust")
	reflector.play("reflect")
	
func end_dash_reflect():
	dust.visible = false
	reflector.visible = false
	hitbox.monitorable = false

	
	

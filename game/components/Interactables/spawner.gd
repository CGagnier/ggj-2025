@tool

extends Node2D

@export var object: PackedScene
@export var delay: float

func spawn():
	var instance = object.instantiate()
	LevelManager.current_level.add_child(instance)
	instance.global_position = global_position

func _ready() -> void:
	if not Engine.is_editor_hint():
		$Sprite2D.visible = false
		
	$Timer.wait_time = delay
	$Timer.timeout.connect(spawn)

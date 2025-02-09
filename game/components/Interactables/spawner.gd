@tool

extends Node2D

@export var object: PackedScene
@export var delay: float

var _object_absorbed = false

func spawn():
	if not _object_absorbed:
		var instance = object.instantiate()
		LevelManager.current_level.add_child(instance)
		instance.global_position = global_position
		
		# Not sure if this is right, but prevent spawning items when you have something absorbed since it can be annoying
		if instance is Interactable:
			instance.absorbed.connect(func(): _object_absorbed = true)
			instance.released.connect(func(): _object_absorbed = false)
	

func _ready() -> void:
	if not Engine.is_editor_hint():
		$Sprite2D.visible = false
		
	$Timer.wait_time = delay
	$Timer.timeout.connect(spawn)

extends Node2D

func _ready():
	LevelManager.launched_from_main = true
	LevelManager.go_to_next_level.call_deferred()
	queue_free()

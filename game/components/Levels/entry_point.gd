extends Node2D

func _ready():
	LevelManager.go_to_next_level.call_deferred()
	queue_free()

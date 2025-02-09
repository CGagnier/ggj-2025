extends Node2D

class_name Level

func _ready():
	## Initialize current level in level_manager
	if not LevelManager.current_level and not LevelManager.launched_from_main:
		LevelManager.current_level = self
	

extends Node

var current_level = null
var next_level_index = 0
const LEVEL_LIST = preload("res://components/Levels/LevelList2.tres")
var overlay = preload("res://UI/overlay.tscn")

func go_to_next_level():
	var _next_level
	if next_level_index >= LEVEL_LIST.levels.size():
		_next_level = LEVEL_LIST.final_level 
	else:
		_next_level = LEVEL_LIST.levels[next_level_index]
		next_level_index += 1
	
	if _next_level.level:
		var _next_level_scene = _next_level.level.instantiate()
		_next_level_scene.name = _next_level.name
	
		var _overlay: OverlayTitle = overlay.instantiate()
		_overlay.title = _next_level.name
	
		add_sibling(_next_level_scene)
		_next_level_scene.add_child(_overlay)
		if current_level:
			current_level.name = "DiscardedLevel"
			current_level.queue_free()
	
		current_level = _next_level_scene
	else:
		print("Level data not valid, can't go to next level if it's not valid, please stop being a noob!")

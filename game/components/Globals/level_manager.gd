extends Node

var current_level = null
var next_level_index = 0
const LEVEL_LIST = preload("res://components/Levels/LevelList.tres")

func _ready() -> void:
	if not current_level:
		return
		#for child in get_parent().get_children():
			## todo: if child is Level
			#var paths = []
			#for scene in LEVEL_LIST.levels:
				#paths.push_back(scene.resource_path)
			 #
			#if child.scene_file_path in paths:
				#current_level = child
		#
		#if not current_level:
			#current_level = LEVEL_LIST.levels[0].instantiate()
			#add_sibling.call_deferred(current_level)

func go_to_next_level():
	var next_level_scene: PackedScene = LEVEL_LIST.levels[next_level_index]
	next_level_index += 1
	
	var next_level = next_level_scene.instantiate()
	next_level.name = "Level"
	add_sibling(next_level)
	if current_level:
		current_level.name = "DiscardedLevel"
		current_level.queue_free()
	
	current_level = next_level

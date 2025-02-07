extends Control

@onready var level_select: ItemList = $LevelSelect
@onready var test_list: ItemList = $Utilities/TestMaps

const TEST_MAPS_LIST = preload("res://components/Levels/tests/test_maps_list.tres")

func _ready() -> void:
	for i in LevelManager.LEVEL_LIST.levels.size():
		var level = LevelManager.LEVEL_LIST.levels[i]
		level_select.add_item("%d - %s" %[i, level.name])
	
	
	level_select.add_item("Final Level")
	level_select.item_selected.connect(_on_level_select)
	
	for i in TEST_MAPS_LIST.levels.size():
		var level = TEST_MAPS_LIST.levels[i]
		test_list.add_item("%d - %s" %[i, level.name])
		
	test_list.item_selected.connect(_on_test_selected)

func _on_level_select(item_index):
	LevelManager.go_to(item_index)
	queue_free()
	
func _on_test_selected(item_index):
	var packed_scene = TEST_MAPS_LIST.levels[item_index].level as PackedScene
	LevelManager.go_to_test_map(packed_scene)
	queue_free()

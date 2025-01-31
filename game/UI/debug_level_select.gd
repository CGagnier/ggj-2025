extends Control

@onready var level_select: ItemList = $LevelSelect

func _ready() -> void:
	for i in LevelManager.LEVEL_LIST.levels.size():
		var level = LevelManager.LEVEL_LIST.levels[i]
		level_select.add_item("%d - %s" %[i, level.name])
	
	
	level_select.add_item("Final Level")
	level_select.item_selected.connect(_on_level_select)

func _on_level_select(item_index):
	LevelManager.go_to(item_index)
	queue_free()

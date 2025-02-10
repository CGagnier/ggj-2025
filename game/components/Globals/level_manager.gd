extends Node

var current_level: Node = null
var next_level_index = 0
const LEVEL_LIST = preload("res://components/Levels/complete/level_flow.tres")
const LEVEL_SELECT_SCENE = preload("res://UI/debug_level_select.tscn")
var overlay = preload("res://UI/overlay.tscn")
var launched_from_main = false

var final_level = false

var level_limit_set
var limits = {"left": 0, "right": 0, "top": 0, "bottom": 0}
var position_smoothing_speed

var death_count: int = 0
var level_death: int = 0

var total_time: float = 0.0 # TODO: Decide if it's time per level, or global
var timer_should_run:= true
var UI: OverlayTitle = null

@onready var play_music = Settings.play_music

func _ready() -> void:
	if play_music:
		$MusicPlayer.play()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		clear_nodes()
		if launched_from_main:
			var _current_level_stat  = LEVEL_LIST.levels[next_level_index-1]
			go_to_level(_current_level_stat, false)
			timer_should_run = true
		else:
			_reload_current_level()
	if Input.is_action_just_pressed("ui_cancel"):
		clear_nodes()
		var level_select = LEVEL_SELECT_SCENE.instantiate()
		add_sibling(level_select)		
		
	if timer_should_run:
		total_time += _delta
	if UI:
		UI.update_time(total_time)

func clear_nodes():
	for node in get_parent().get_children():
		if not ProjectSettings.has_setting("autoload/%s" % node.name):
			node.queue_free()

func go_to_next_level():
	go_to(next_level_index)
	
	# Don't play chime when you enter the game
	if next_level_index != 1:
		$AudioStreamPlayer2D.play()

func go_to(level_index: int):
	level_death = 0
	
	var _next_level
	var _final = false
	
	if level_index >= LEVEL_LIST.levels.size():
		timer_should_run = false 
		$MusicPlayer.stop()
		_next_level = LEVEL_LIST.final_level
		_final = true
	else:
		_next_level = LEVEL_LIST.levels[level_index]
		next_level_index = level_index + 1
	
	go_to_level(_next_level, _final)

func go_to_test_map(map:PackedScene):
	var map_instance = map.instantiate()
	if current_level:
		current_level.name = "DiscardedLevel"
		current_level.queue_free()
	
	current_level = map_instance
	add_sibling(map_instance)
	

func go_to_level(level: LevelStat, _is_final: bool):
	if level:
		var _next_level_scene = level.level.instantiate()
		if level.name.length():
			_next_level_scene.name = level.name

		## TODO: Overlay should always be loaded ? 
		var _overlay: OverlayTitle = overlay.instantiate()
		_overlay.title = level.name
		UI = _overlay
		UI.current_deaths = death_count

		add_sibling(_next_level_scene)
		_next_level_scene.add_child(_overlay)
		
		if _is_final:
			UI.hide_overlays()

		if current_level:
			current_level.name = "DiscardedLevel"
			current_level.queue_free()

		current_level = _next_level_scene
	else:
		print("Level data not valid, can't go to next level if it's not valid, please stop being a noob!")

func increase_deaths() -> void:
	death_count += 1
	level_death += 1
	if UI:
		UI.update_death_count(death_count)
	print("total: ", death_count, " level deaths: ", level_death)

func get_formatted_total_time() -> String:
	if UI:
		return UI.format_time(total_time)
	else: # Not loaded using level manager
		return "00:00:00" 

## NOTE: Only to be used when running a single scene
func _reload_current_level():
	var scene_path = current_level.scene_file_path
	var level_stat:LevelStat = LevelStat.new()
	
	level_stat.level = load(scene_path)
	total_time = 0.0
	
	go_to_level(level_stat, false)

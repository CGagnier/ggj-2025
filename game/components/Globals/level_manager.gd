extends Node

var current_level = null
var next_level_index = 0
const LEVEL_LIST = preload("res://components/Levels/complete/level_flow.tres")
const LEVEL_SELECT_SCENE = preload("res://UI/debug_level_select.tscn")
var overlay = preload("res://UI/overlay.tscn")

var level_limit_set
var limits = {"left": 0, "right": 0, "top": 0, "bottom": 0}
var position_smoothing_speed

var death_count: int = 0
var level_death: int = 0

var total_time: float = 0.0 # TODO: Decide if it's time per level, or global
var timer_should_run:= true
var UI: OverlayTitle = null

@onready var play_music = Settings.play_music

func _reset_camera_settings() -> void:
	level_limit_set = false
	position_smoothing_speed = 5.0 # Default

func _ready() -> void:
	_reset_camera_settings()
	if play_music:
		$MusicPlayer.play()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		clear_nodes()
		_load_current_level(1)
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

## Level Index Modifier used to NOT increase 
func _load_current_level(level_index_modifier=0) -> void:
	
	var _next_level
	
	_next_level = LEVEL_LIST.levels[next_level_index-level_index_modifier]
	_reset_camera_settings()
	var _next_level_scene = _next_level.level.instantiate()
	_next_level_scene.name = _next_level.name if _next_level.name.length() else "EmptyNameLevel"

	var _overlay: OverlayTitle = overlay.instantiate()
	_overlay.title = _next_level.name

	add_sibling(_next_level_scene)
	_next_level_scene.add_child(_overlay)
	current_level = _next_level_scene

func go_to_next_level():
	go_to(next_level_index)
	if next_level_index != 1:
		# Don't play chime when you enter the game
		$AudioStreamPlayer2D.play()

func go_to(level_index: int):
	level_death = 0
	_reset_camera_settings()
	
	var _next_level
	
	if level_index >= LEVEL_LIST.levels.size():
		timer_should_run = false 
		$MusicPlayer.stop()
		_next_level = LEVEL_LIST.final_level
	else:
		_next_level = LEVEL_LIST.levels[level_index]
		next_level_index = level_index + 1
	
	go_to_level(_next_level)

func go_to_level(level: LevelStat):
	if level:
		var _next_level_scene = level.level.instantiate()
		if level.name.length():
			_next_level_scene.name = level.name
	
		var _overlay: OverlayTitle = overlay.instantiate()
		_overlay.title = level.name
		UI = _overlay
	
		add_sibling(_next_level_scene)
		_next_level_scene.add_child(_overlay)
		if current_level:
			current_level.name = "DiscardedLevel"
			current_level.queue_free()

		current_level = _next_level_scene
	else:
		print("Level data not valid, can't go to next level if it's not valid, please stop being a noob!")

#region Camera globals
func set_current_camera_limits(left, top, right, bottom) -> void:

	if not level_limit_set:
		limits.left = left
		limits.right = right
		limits.top = top
		limits.bottom = bottom
		level_limit_set = true
	else:
		print("limits already set, try again next time?")

func get_current_camera_limits() -> Array:
	return [limits.left, limits.top, limits.right, limits.bottom]

func set_camera_smoothing_speed(speed) -> void:
	position_smoothing_speed = speed

func get_camera_smoothing_speed() -> float:
	return position_smoothing_speed
#endregion
	
func increase_deaths() -> void:
	death_count += 1
	level_death += 1
	print("total: ", death_count, " level deaths: ", level_death)

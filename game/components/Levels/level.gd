@tool

extends Node2D

class_name Level

signal player_spawned
signal player_died
signal finished_move

@onready var camera = $SmartCamera2D
@onready var _limits_were_set = camera.limit_right == -10000000

@export_tool_button("Approximate Limits") var approxmiate_limits = _set_level_limits

var _waiting_for_movement = false

func _ready():
	## Initialize current level in level_manager
	if not LevelManager.current_level and not LevelManager.launched_from_main:
		LevelManager.current_level = self
	
	camera.target_mode = camera.TARGET_MODE.GROUP
	camera.group_name = "Door"
	update_camera.call_deferred()
	player_spawned.connect(_on_player_spawned)
	player_died.connect(_on_player_died)
	
func _process(delta: float) -> void:
	if _waiting_for_movement:
		if camera.distance_to_target <= 0.1:
			_waiting_for_movement = false
			finished_move.emit()


func update_camera():
	camera.target_nodes.clear()
	camera._refresh_targets()
	_waiting_for_movement = true
	
func _on_player_died():
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 1.0
	camera.group_name = "Door"
	update_camera()


func _on_player_spawned():
	camera.group_name = "Player"
	camera.position_smoothing_enabled = false
	update_camera()
	
func _set_level_limits():
	# prototype code
	var rect: Rect2i = $Background.get_used_rect()
	if not _limits_were_set:
		var x_margin = 32 * 2
		camera.limit_left = rect.position.x * 32 - x_margin
		camera.limit_top = rect.position.y * 32 - 32
		camera.limit_right = rect.position.x * 32 + rect.size.x * 32 + x_margin
		camera.limit_bottom = rect.position.y * 32 + rect.size.y * 32 + 32
	

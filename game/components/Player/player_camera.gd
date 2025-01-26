extends Camera2D


func _ready() -> void:
	if not LevelManager.level_limit_set:
		LevelManager.set_current_camera_limits(limit_left,limit_top,limit_right,limit_bottom)
	else:
		var limits = LevelManager.get_current_camera_limits()
		limit_left = limits[0]
		limit_top = limits[1]
		limit_right = limits[2]
		limit_bottom = limits[3]

	make_current()
	get_tree().create_timer(2).timeout.connect(func(): position_smoothing_enabled = true)

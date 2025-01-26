extends Camera2D


func _ready() -> void:
	make_current()
	get_tree().create_timer(2).timeout.connect(func(): position_smoothing_enabled = true)

extends Control
class_name OverlayTitle

@export var title:String = "Testtt"
@onready var label = $CenterContainer/Label

func _ready() -> void:
	label.text = title
	var _tween = get_tree().create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 2).set_ease(Tween.EASE_IN_OUT).set_delay(1)

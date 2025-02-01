extends CanvasLayer
class_name OverlayTitle

@export var title:String = "Test"

@onready var level_title = $LevelTitle
@onready var label = $LevelTitle/CenterContainer/Label

@onready var timer_label:Label = $MarginContainer/Label
var should_be_visible = true

func _ready() -> void:
	timer_label.visible = should_be_visible
	label.text = title
	var _tween = get_tree().create_tween()
	_tween.tween_property(level_title, "modulate:a", 0.0, 2).set_ease(Tween.EASE_IN_OUT).set_delay(1)

func format_time(elapse_time: float) -> String:
	var _mms: float = fmod(elapse_time, 1) * 100
	var _s: float = fmod(elapse_time, 60.0)
	var _m: int = int(elapse_time / 60.0) % 60
	var formatted_time: String = "%02d:%02d:%02d" % [_m, _s, _mms]
	
	return formatted_time

func update_time(elapse_time: float) -> void:
	timer_label.text = format_time(elapse_time)

func hide_timer() -> void:
	should_be_visible = false

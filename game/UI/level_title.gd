extends CanvasLayer
class_name OverlayTitle

@export var title:String = "Test"

@onready var level_title = $LevelTitle
@onready var label = $LevelTitle/CenterContainer/Label

var should_be_visible = true
var level_title_visible = true

@onready var timer_label:Label = $MarginContainer/Label
@onready var death_count: = $DeathContainer
@onready var death_count_label: Label = $DeathContainer/HBoxContainer/Label
var current_deaths = 0

func _ready() -> void:
	timer_label.visible = should_be_visible
	death_count.visible = should_be_visible
	label.text = title
	death_count_label.text = str(current_deaths)
	
	level_title.visible = level_title_visible
	
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

func update_death_count(deaths: int) -> void:
	current_deaths = deaths
	death_count_label.text = str(deaths)

func hide_overlays() -> void:
	should_be_visible = false

func hide_title() -> void:
	level_title_visible = false

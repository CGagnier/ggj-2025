extends Area2D

class_name PlatformWaypoint

@export var delay:float = 1.0
@export var next_waypoint:PlatformWaypoint = null

@onready var sprite:Sprite2D = $Sprite2D

var currentPlatform: PlatformMoving = null

func _ready() -> void:
	sprite.visible = false

func _process(delta: float) -> void:
	pass

# Should detect only moving platform layer
func _on_area_entered(area: Area2D) -> void:
	if area is PlatformMoving and next_waypoint and !currentPlatform:
		currentPlatform = area
		currentPlatform.set_next_waypoint(next_waypoint, delay)

func _on_area_exited(area: Area2D) -> void:
	if area == currentPlatform:
		currentPlatform = null

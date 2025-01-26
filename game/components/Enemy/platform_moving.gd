extends Area2D

class_name PlatformMoving

@export var speed:float = 50.0
@export var initial_waypoint:PlatformWaypoint = null

@onready var sprite:Sprite2D = $Sprite2D

var next_waypoint:PlatformWaypoint = null
var isMoving = false
var timeleft:float

func _ready() -> void:
	sprite.visible = false
	if initial_waypoint:
		next_waypoint = initial_waypoint
		start_moving()

func _process(delta: float) -> void:
	if isMoving:
		update_movement(delta)
	else:
		if timeleft > 0:
			timeleft -= delta
		else :
			start_moving()

func set_next_waypoint(waypoint:PlatformWaypoint, delay:float ) -> void:
	next_waypoint = waypoint
	timeleft = delay
	stop_moving()
	pass

func start_moving() -> void:
	if !isMoving:
		isMoving = true
	
func stop_moving() -> void:
	if isMoving:
		isMoving = false

func update_movement(delta: float) -> void:
	if next_waypoint:
		var currentPosition = global_position
		var direction = next_waypoint.global_position-currentPosition
		direction = direction.normalized()
		global_position = currentPosition + direction*speed*delta

extends RigidBody2D
class_name Bubble


@export var speed = 4

var launched = false
var new_scale: Vector2

func _physics_process(delta: float) -> void:
	if launched:
		scale = new_scale
		move_and_collide(Vector2(1,0) *  speed)

func release(_scale: Vector2) -> void:
	scale = _scale
	new_scale = _scale
	launched = true

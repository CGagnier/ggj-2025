extends RigidBody2D

class_name Ball

@export var stat: BallStat

# Var from BallStat
var speed = null
var timeToDestroy: float = 0.0

# Local var
var direction = null
var lifeTime = 0.0

func _ready() -> void:
	speed = stat.speed
	timeToDestroy = stat.timeToDestroy
	gravity_scale = stat.gravity_scale
	lock_rotation = stat.lock_rotation
	start_movement()

func _process(delta: float) -> void:
	if(timeToDestroy > 0.0):
		if(lifeTime > timeToDestroy):
			DestroyBall()
		else:
			lifeTime = lifeTime + delta

func start_movement() -> void:
	apply_impulse(direction*speed)

func DestroyBall() -> void:
	# Todo Spawn Destroy VFX 
	queue_free()

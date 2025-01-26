extends RigidBody2D

class_name Ball

@export var stat: BallStat
@onready var collision: CollisionShape2D = $CollisionShape2D

# Local var
var direction = null
var lifeTime = 0.0

func _ready() -> void:
	gravity_scale = stat.gravity_scale
	lock_rotation = stat.lock_rotation
	start_movement()

func _process(delta: float) -> void:
	if(stat.timeToDestroy > 0.0):
		if(lifeTime > stat.timeToDestroy):
			DestroyBall()
		else:
			lifeTime = lifeTime + delta

func start_movement() -> void:
	apply_impulse(direction*stat.speed)

func DestroyBall() -> void:
	# Todo Spawn Destroy VFX 
	queue_free()

func _on_body_entered(body: Node) -> void:
	print("Collision!")
	if (body is not Canon):
		if (stat.can_explode):
			if(body is Player):
				var player: Player = body
				if(player.alive):
					player._dying()
					DestroyBall()
			elif(body is Bubble):
				var bubble: Bubble = body
				bubble.queue_free()
				DestroyBall()
			else:
				DestroyBall()

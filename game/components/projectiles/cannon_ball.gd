extends RigidBody2D

class_name Ball

@export var stat: BallStat
@onready var collision: CollisionShape2D = $CollisionShape2D

# Local var
var direction = null
var lifeTime = 0.0
var can_explode_cannon = false
## If its being sent back to cannon, used to ensure it cant kill the player in that case
var sent_back = false

@onready var initial_velocity =  direction*stat.speed

func _ready() -> void:
	gravity_scale = stat.gravity_scale
	lock_rotation = stat.lock_rotation
	# Dont kill the cannon ball on spawn
	get_tree().create_timer(0.3).timeout.connect(func(): can_explode_cannon = true)
	
	linear_velocity = initial_velocity

func _process(delta: float) -> void:
	if(stat.timeToDestroy > 0.0):
		if(lifeTime > stat.timeToDestroy):
			DestroyBall()
		else:
			lifeTime = lifeTime + delta

func DestroyBall() -> void:
	# Todo Spawn Destroy VFX 
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body is BreakablePillar:
		body.destroy()
		linear_velocity = Vector2.ZERO
		get_tree().create_timer(0.05).timeout.connect(set_deferred.bind("linear_velocity", initial_velocity))
		#set_deferred.bind("freeze", true)
		#get_tree().create_timer(0.4).timeout.connect(set_deferred.bind("freeze", false))
		
	elif body is Canon:
		if can_explode_cannon:
			(body as Canon).destroy()
			DestroyBall()
	elif not sent_back:
		if (stat.can_explode):
			if(body is Player):
				var player: Player = body
				if(player.alive):
					player._dying()
					DestroyBall()
			elif(body is Bubble):
				sent_back = true
				var bubble: Bubble = body
				
				if not bubble.launched:
					bubble.get_parent()._let_go.call_deferred()
					
				# todo: if collision is on the side that makes sense for it to pop, then boucne it back, otherwise just push it out of the way
				var tween = get_tree().create_tween()
				
				tween.tween_property(self, "linear_velocity", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_CUBIC)
				var bounce_dir= -direction*stat.speed * 4.5
				tween.tween_callback(apply_impulse.bind(bounce_dir)).set_delay(0.2)
				tween.tween_callback(bubble.queue_free).set_delay(0.012)
				#apply_impulse(-direction*stat.speed /4)
				#get_tree().create_timer(0.2).timeout.connect(apply_impulse.bind(-direction*stat.speed * 4))
				#DestroyBall()
			else:
				DestroyBall()

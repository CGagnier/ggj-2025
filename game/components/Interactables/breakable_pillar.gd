extends RigidBody2D

class_name BreakablePillar

func destroy():
	# TODO play sound
	# TODO: Spawn pillar segments or particles
	
	var tween = get_tree().create_tween()
	#$CollisionShape2D.set_deferred("disabled", true) 
	tween.tween_property(self, "scale", Vector2(1, 0), 0.3)
	tween.tween_callback(queue_free)

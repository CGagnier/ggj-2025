extends RigidBody2D

class_name BreakablePillar

@export var pieces_scene: PackedScene

func destroy():
	# TODO play sound
	# TODO: Spawn pillar segments or particles
	
	var pieces = pieces_scene.instantiate()
	pieces.global_position = global_position
	add_sibling.call_deferred(pieces)
	queue_free()
	
	#var tween = get_tree().create_tween()
	##$CollisionShape2D.set_deferred("disabled", true) 
	#tween.tween_property(self, "scale", Vector2(1, 0), 0.3)
	#tween.tween_callback(queue_free)

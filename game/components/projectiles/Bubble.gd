extends CharacterBody2D

class_name Bubble

@export var speed = 2

var launched = false

func _physics_process(delta: float) -> void:
	if launched:
		var collision = move_and_collide(Vector2(1,0) *  speed)
		if collision:
			if collision.get_collider() is Bubble:
				var scene:PackedScene = load(scene_file_path)
				var new_instance = scene.instantiate()
				
				var other_bubble = collision.get_collider() as Bubble
				
				collision.get_collider().queue_free()
				queue_free()
				get_parent().add_child(new_instance)
				
				#new_instance.global_position = (other_bubble.global_position - global_position) / 2 + global_position
				var total_length = (global_scale.length() + other_bubble.global_scale.length()) / 2
				#ce bout la est degueulasse je vais le changer
				new_instance.get_node("JumpPad").monitoring = true
				new_instance.global_position = global_position
				new_instance.scale = scale
				new_instance.speed = 0
				
				var collision_tween = get_tree().create_tween()
				var target_position = (other_bubble.global_position - global_position) / 2 + global_position
				collision_tween.set_parallel()
				collision_tween.tween_property(new_instance, "global_position", target_position, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
				collision_tween.tween_property(new_instance, "scale", Vector2(1,1) * total_length, 0.3).set_trans(Tween.TRANS_ELASTIC)
				
func release() -> void:
	launched = true
	$JumpPad.monitoring = true

func _on_jump_pad_body_entered(body: Node2D) -> void:
	print(body)
	if body.velocity.y > 0:
		speed = 0
		var tween = get_tree().create_tween()
		body.velocity.y = 0
		
		#tween.tween_property(self, "scale", Vector2(1, 0.9), 0.05).set_trans(Tween.TRANS_BOUNCE)
		var start_position_y = $Sprite2D.position.y
		tween.tween_property($Sprite2D, "position:y", start_position_y + 1, 0.05).set_trans(Tween.TRANS_BOUNCE)
		var scale_modifier = scale.length() * 0.5
		tween.tween_property(body, "velocity:y", body.JUMP_VELOCITY * scale_modifier, 0.01).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(queue_free)
		
		#body.velocity.y = body.JUMP_VELOCITY
		

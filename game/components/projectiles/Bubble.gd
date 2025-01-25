extends CharacterBody2D

class_name Bubble

@export var speed = 2

@export var start_speed = 5
@export var final_speed = 4

var launched = false
var dir = Vector2.RIGHT
var inflate_percent := 0.0

var t := 0.0

var collided = false
var body_started_in_bubble = false

func _physics_process(delta: float) -> void:
	if launched:
		t += delta * 2
		t = min(t, 1.0)
		
		# Activate bounce after a small delay
		speed = lerpf(start_speed, final_speed, t)
		
		var collision = move_and_collide(dir *  speed)
		
		if collision and not collided:
			if collision.get_collider() is Bubble:
				var scene:PackedScene = load(scene_file_path)
				var new_instance = scene.instantiate()
				
				var other_bubble = collision.get_collider() as Bubble
				other_bubble.collided = true # prevent other bubble from detecting same collision
				
				collision.get_collider().queue_free()
				queue_free()
				get_parent().add_child(new_instance)
				
				#new_instance.global_position = (other_bubble.global_position - global_position) / 2 + global_position
				var total_length = 0.5*(global_scale.length() + other_bubble.global_scale.length())
				#ce bout la est degueulasse je vais le changer
				
				new_instance.global_position = global_position
				new_instance.scale = scale
				new_instance.start_speed = 0
				new_instance.final_speed = 0
				new_instance.launched = true
				
				var collision_tween = get_tree().create_tween()
				var target_position = (other_bubble.global_position - global_position) / 2 + global_position
				collision_tween.set_parallel()
				collision_tween.tween_property(new_instance, "global_position", target_position, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
				collision_tween.tween_property(new_instance, "scale", Vector2(1,1) * total_length, 0.3).set_trans(Tween.TRANS_ELASTIC)
			else:
				dir = dir.bounce(collision.get_normal())
				
func release() -> void:
	launched = true
	speed = start_speed
	# Scale down the speed according to inflation percent so that bigger bubbles 
	# move slower
	const _inflate_percent_influence = 0.7
	final_speed = final_speed * (1-inflate_percent * _inflate_percent_influence)

func _on_jump_pad_body_entered(body: Node2D) -> void:
	# todo: Restrict this to Player class? 
	if not launched:
		body_started_in_bubble = true
			
	if body.velocity.y > 0:
		if launched and not body_started_in_bubble:
			# Prevent the player from boucning around when shooting left or right while in the bubble
			# Note: This does not work.
			
			speed = 0
			var tween = get_tree().create_tween()
			body.velocity.y = 0
			
			var base_scale = scale
			#tween.tween_property(self, "scale", scale * Vector2(1, 0.9), 0.05).set_trans(Tween.TRANS_BOUNCE)
			#tween.tween_property(self, "scale", base_scale, 0.05).set_trans(Tween.TRANS_CUBIC)
			var start_position_y = $Sprite2D.position.y
			tween.tween_property($Sprite2D, "position:y", start_position_y + 1, 0.05).set_trans(Tween.TRANS_BOUNCE)
			var scale_modifier = scale.length() * 0.5
			var jump_force = body.JUMP_VELOCITY * scale_modifier
			tween.tween_property(body, "velocity:y", jump_force, 0.01).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_callback(queue_free)
		else:
			body_started_in_bubble = true


func _on_jump_pad_body_exited(body: Node2D) -> void:
	if not launched:
		body_started_in_bubble = false

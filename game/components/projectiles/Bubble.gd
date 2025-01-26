extends CharacterBody2D

class_name Bubble

signal on_disappear

@export var speed = 2
@export var start_speed = 5
@export var final_speed = 4

var launched = false
var dir = Vector2.RIGHT
var inflate_percent := 0.0

var t := 0.0

var collided = false
var body_started_in_bubble = false
var absorbed_entity = null
var _speed_multiplier = 1

@onready var raycast = $RayCast2D


func _physics_process(delta: float) -> void:
	
	if launched:
		t += delta * 2
		t = min(t, 1.0)
		
		# Activate bounce after a small delay
		speed = lerpf(start_speed, final_speed, t) * _speed_multiplier
		
		var collision = move_and_collide(dir *  speed)
		
		if collision and not collided:
			
			var collided = collision.get_collider()
			if collided is Bubble:
				pass
				#_handle_bubble_collision(collided as Bubble)
			elif collided is Interactable:
				if not absorbed_entity:
					_handle_interactable_collision.call_deferred(collided as Interactable)
			else:
				# re-enable to bounce
				#dir = dir.bounce(collision.get_normal())
				if collided is not Player:
					if (collision.get_normal() * dir).length() > 0:
						_delay_die()
				
func _delay_die() -> void: 
	_speed_multiplier = 0
	await get_tree().create_timer(.5).timeout
	queue_free()

func release() -> void:
	launched = true
	speed = start_speed
	# Scale down the speed according to inflation percent so that bigger bubbles 
	# move slower
	const _inflate_percent_influence = 0.7
	
func absorb(interactable: Interactable):
	absorbed_entity = interactable
	
	var tween = get_tree().create_tween()
	
	var target_position = interactable.global_position
	
	# absord method
	interactable.get_node("CollisionShape2D").disabled = true
	interactable.z_index = 0
	interactable.z_as_relative = false
	interactable.gravity_scale = 0
	$Sprite2D.self_modulate *= 0.7
	
	_speed_multiplier = 0
	
	tween.tween_property(self, "position", target_position, 0.2)#.set_delay(0.1)
	tween.tween_callback(func(): interactable.reparent(self))
	
	
	#tween.set_parallel()
	#tween.tween_property(self, "speed", 0, 0.3).set_delay(0.8)
	tween.tween_property(self, "_speed_multiplier", 1, 0.3)

func _handle_bubble_collision(other_bubble: Bubble):
	var scene:PackedScene = load(scene_file_path)
	var new_instance = scene.instantiate()
	other_bubble.collided = true # prevent other bubble from detecting same collision
	other_bubble.queue_free()
	queue_free()
	
	add_sibling(new_instance)
	
	new_instance.global_position = global_position
	new_instance.scale = scale
	new_instance.start_speed = 0
	new_instance.final_speed = 0
	new_instance.launched = true
	
	var collision_tween = get_tree().create_tween()
	var target_position = (other_bubble.global_position - global_position) / 2 + global_position
	collision_tween.set_parallel()
	collision_tween.tween_property(new_instance, "global_position", target_position, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	var total_length = 0.5*(global_scale.length() + other_bubble.global_scale.length())
	collision_tween.tween_property(new_instance, "scale", Vector2(1,1) * total_length, 0.3).set_trans(Tween.TRANS_ELASTIC)

func _handle_interactable_collision(interactable: Interactable):
	absorb(interactable)
	dir = Vector2.UP

func _on_jump_pad_body_entered(body: Node2D) -> void:
	# todo: Restrict this to Player class? 
	if not launched:
		body_started_in_bubble = true
	
	body_started_in_bubble = false #hack
			
	if body.velocity.y > 0:
		if launched and not body_started_in_bubble and raycast.is_colliding():
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
			var scale_modifier = scale.length()
			var jump_force = body.JUMP_VELOCITY * scale_modifier
			tween.tween_property(body, "velocity:y", jump_force, 0.01).set_trans(Tween.TRANS_BOUNCE)
			tween.tween_callback(queue_free)
		else:
			body_started_in_bubble = true


func _on_jump_pad_body_exited(body: Node2D) -> void:
	if not launched:
		body_started_in_bubble = false

func _release_item():
	if absorbed_entity:
		var tree = get_tree()
		if tree:
			absorbed_entity.reparent(get_parent())
			absorbed_entity.get_node("CollisionShape2D").disabled = false
			absorbed_entity.z_as_relative = true
			absorbed_entity.gravity_scale = 1
			absorbed_entity = null

func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			on_disappear.emit()
			_release_item()

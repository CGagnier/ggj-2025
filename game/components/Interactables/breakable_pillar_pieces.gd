extends Node2D

func _ready() -> void:
	_add_force(Vector2(100, -50))
	$ImpactPlayer.play()
	$CrumblePlayer.play()
	
	var tween = get_tree().create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, 1).set_delay(3)
	tween.tween_callback(queue_free)
	
func _set_scale(value: float):
	for child in get_children():
		if child is RigidBody2D:
			pass
			#child.scale = value

func _set_alpha(value):
	for child in get_children():
		if child is RigidBody2D:
			child.get_node("Sprite2D").self_modulate.a = value
			
func _add_force(force):
	for child in get_children():
		if child is RigidBody2D:
			child.apply_impulse(force)

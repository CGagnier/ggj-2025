extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body._dying()
		# TODO: Swap body with rigibody + add impulse
	if body is Bubble:
		body.queue_free()

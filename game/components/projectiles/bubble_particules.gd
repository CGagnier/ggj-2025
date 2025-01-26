extends CPUParticles2D

var has_fired = false

func fire() -> void:
	has_fired = true
	emitting = true

func _on_finished() -> void:
	queue_free()

extends Node2D

var fell = false

func _on_body_entered(body: Node2D) -> void:
	if not fell:
		fell = true
		$Crate.set_deferred("freeze", false)
		$Crate.set_deferred("sleeping", false)

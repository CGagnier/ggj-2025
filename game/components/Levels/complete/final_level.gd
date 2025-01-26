extends Node2D


func _ready():
	$Timer.timeout.connect(emit_particle)

func emit_particle():
	var children = $Node.get_children()
	var particle = children.pick_random()
	if particle:
		particle.emitting = true
	

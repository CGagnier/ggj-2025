extends Node2D


func _ready():
	$Timer.timeout.connect(emit_particle)

func emit_particle():
	var children = $Node.get_children()
	if children.size():
		var particle = children.pick_random()
		if particle:
			particle.emitting = true
			$FireworkAudio.play()
	

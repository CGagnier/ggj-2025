extends Node2D


func _ready():
	$Timer.timeout.connect(emit_particle)
	
	# Get total time, and hide the overlay one
	$Control/FinalTime.text = LevelManager.get_formatted_total_time()

func emit_particle():
	var children = $Particules.get_children()
	if children.size():
		var particle = children.pick_random()
		if particle:
			particle.emitting = true
			$FireworkAudio.play()
	

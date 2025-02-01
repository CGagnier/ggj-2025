extends Node2D


func _ready():
	$Timer.timeout.connect(emit_particle)
	
	# Get total time
	$Control/FinalTime.text = LevelManager.get_formatted_total_time()
	
	# Get total deaths
	var _default_death_label = "You died %s time%s!"
	var _death_count = LevelManager.death_count
	var _death_plural = "" if _death_count == 1 else "s" # Bit overkil
	
	$Control/TotalDeaths.text = _default_death_label % [_death_count, _death_plural]

func emit_particle():
	var children = $Particules.get_children()
	if children.size():
		var particle = children.pick_random()
		if particle:
			particle.emitting = true
			$FireworkAudio.play()
	

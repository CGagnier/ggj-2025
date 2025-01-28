extends Node2D

func _ready():
	create_tween().tween_callback(queue_free).set_delay(5)
	
	for child in $Parts.get_children():
		child.body_entered.connect($AudioStreamPlayer2D.play.unbind(1))

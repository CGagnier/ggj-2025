extends AnimatedSprite2D

func _ready():
	get_tree().create_timer(1).timeout.connect(open)
	animation_finished.connect(anim_finished)
	
func open():
	animation = "open"
	play()
	
func close():
	animation = "close"
	play()

func anim_finished():
	if animation == "open":
		get_tree().create_timer(1).timeout.connect(close)
	

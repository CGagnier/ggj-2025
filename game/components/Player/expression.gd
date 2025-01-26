extends AnimatedSprite2D

func _ready():
	animation_finished.connect(_on_anim_finished)

func play_wtf():
	play("wtf in")
	
func _on_anim_finished():
	if animation == "wtf in":
		get_tree().create_timer(0.5).timeout.connect(_play_out)	
	if animation == "wtf out":
		play("default")

func _play_out():
	play("wtf out")

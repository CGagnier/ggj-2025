extends AnimatedSprite2D

@export var is_exit = false
var can_open = true
var has_exited = false

#const PLAYER_SCENE = preload("res://components/Player/player.tscn")
@export var PLAYER_SCENE: PackedScene

signal level_over

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
	if animation == "open" and not is_exit:
		var player = PLAYER_SCENE.instantiate()
		get_tree().root.add_child(player)
		player.global_position = global_position
		get_tree().create_timer(1).timeout.connect(close)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_exit and not has_exited:
		print('Exit!')
		#if body is player
		has_exited = true
		body.queue_free()
		LevelManager.go_to_next_level.call_deferred()

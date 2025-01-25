extends AnimatedSprite2D

@export var is_exit = false
@export var can_open = true
var has_exited = false
var is_open = false

#const PLAYER_SCENE = preload("res://components/Player/player.tscn")
@export var PLAYER_SCENE: PackedScene

signal level_over

func _ready():
	if can_open:
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
		if not is_exit:
			spawn()
		else:
			is_open = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_open and is_exit and not has_exited:
		#if body is player
		has_exited = true
		body.queue_free()
		LevelManager.go_to_next_level.call_deferred()

func spawn() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	get_tree().root.add_child(player)
	player.global_position = global_position
	player.connect("died",spawn)
	get_tree().create_timer(1).timeout.connect(close)

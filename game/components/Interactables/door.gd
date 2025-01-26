extends AnimatedSprite2D

@export var is_exit = false
@export var can_open = true
var has_exited = false
var is_open = false
var player_in: Player = null

#const PLAYER_SCENE = preload("res://components/Player/player.tscn")
@export var PLAYER_SCENE: PackedScene

signal level_over

func _ready():
	if can_open:
		get_tree().create_timer(1).timeout.connect(open)
	animation_finished.connect(anim_finished)
	
func open():
	play("open")
	
func close():
	play("close")
	
func anim_finished():
	if animation == "open":
		if not is_exit:
			spawn()
		else:
			is_open = true
			if player_in:
				go_to_next_level(player_in)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Body should be the player because collision mask
	player_in = body 
	if is_open and is_exit and not has_exited:
		go_to_next_level(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	player_in = null

func spawn() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	add_sibling(player)
	player.global_position = global_position
	player.connect("died",open)
	get_tree().create_timer(1).timeout.connect(close)
	
func go_to_next_level(body: Node2D) -> void:
	has_exited = true
	body.queue_free()
	LevelManager.go_to_next_level.call_deferred()

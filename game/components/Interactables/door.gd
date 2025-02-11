extends AnimatedSprite2D

@export var is_exit = false
@export var can_open = true
@export var door_open_delay := 0.3
@export var time_to_respawn := 0.6

const PLAYER_EXIT_LEVEL = preload("res://components/Player/player_exit_level.tscn")

var has_exited = false
var is_open = false
var player_in: Player = null

#const PLAYER_SCENE = preload("res://components/Player/player.tscn")
@export var PLAYER_SCENE: PackedScene

func _ready():
	if not is_exit:
		add_to_group("Door")
	
	if can_open:
		get_tree().create_timer(door_open_delay).timeout.connect(open)
	animation_finished.connect(anim_finished)
	
func open():
	play("open")
	$AudioStreamPlayer2D.play()
	$AudioStreamPlayer2D.stream.set("parameters/switch_to_clip", "Open")
	
func close():
	play("close")
	$AudioStreamPlayer2D.get_stream_playback().switch_to_clip_by_name("Door Close")
	
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

func _on_area_2d_body_exited(_body: Node2D) -> void:
	player_in = null

func _player_death() -> void:
	LevelManager.increase_deaths()
	await LevelManager.current_level.finished_move
	LevelManager.reset_level_state()

func spawn() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	add_sibling(player)
	player.global_position = global_position
	player.died.connect(_player_death)
	player.died.connect(LevelManager.current_level.player_died.emit)
	LevelManager.current_level.player_spawned.emit()
	get_tree().create_timer(time_to_respawn).timeout.connect(close)
	
func go_to_next_level(body: Node2D) -> void:
	has_exited = true
	var exit_anim = PLAYER_EXIT_LEVEL.instantiate()
	exit_anim.z_index = body.z_index
	body.add_sibling(exit_anim)
	exit_anim.global_transform = body.global_transform
	exit_anim.scale.x *= -1 if body.get_node("AnimatedSprite2D").flip_h else 1
	#exit_anim.flip_h = body.get_node("AnimatedSprite2D").flip_h
	body.queue_free()
	var anim_player = exit_anim.get_node("AnimationPlayer")
	anim_player.animation_finished.connect(LevelManager.go_to_next_level.unbind(1))
	#anim_player.play("exit")

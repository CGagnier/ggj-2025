extends Node2D

signal bubble_popped

@export var ProjectileScene: PackedScene
@export var start_scale = Vector2(0.5, 0.5)
@export var max_scale: Vector2 = Vector2(2,2)
@export var growth_rate := 1.0
@export var indicator: BubbleIndicator
@export var time_before_bubble_pop := 0.5
## How long you can hold a 'full' bubble before it pops
@export var time_to_full_bubble := 1.0

var is_tweening = false
var _tween = null
#
var _grow_time := 0.0

var current_projectile: Node2D = null

const shoot_dirs = ["shoot_left", "shoot_up", "shoot_right", "shoot_down"]

var last_pressed_timestamps = [0.0, 0.0, 0.0, 0.0]
var _current_bullets = 3
var _time_with_full_bubble := 0.0
var _can_create_bubble = true

var num_bullets:
	set(val):
		_current_bullets = val
		indicator.num_gums = val
	get:
		return _current_bullets

var input_to_dir: Dictionary[String, Vector2] = {
	shoot_dirs[0]: Vector2.LEFT,
	shoot_dirs[1]: Vector2.UP,
	shoot_dirs[2]: Vector2.RIGHT,
	shoot_dirs[3]: Vector2.DOWN
}

var current_shoot_dir = Vector2.RIGHT

var release_time := 0.0
var released = false
var release_to_let_go_time := 0.1

func _input(event: InputEvent) -> void:
	pass
	
func _process(delta: float) -> void:
	var offset = 10 * current_shoot_dir
	if current_projectile:
		current_projectile.position = offset
	

func _physics_process(delta: float) -> void:
	if released:
		release_time += delta
		
		if release_time >= release_to_let_go_time:
			_let_go()
			released = false
			release_time = 0
	
	var last_index = -1
	var last_pressed_timestamp = -1
	
	for i in 4:
		var shoot_dir = shoot_dirs[i]
		if Input.is_action_just_pressed(shoot_dir) and not current_projectile:
			if num_bullets <= 0:
				# Alert no bullet
				continue
				
			_create_bubble()
			
			last_pressed_timestamps[i] = Time.get_unix_time_from_system()
			
			# Keep tracked of which key was pressed last.
			var ts = last_pressed_timestamps[i]
			if ts > last_pressed_timestamp:
				last_pressed_timestamp = ts
				last_index = i
	
	for shoot_dir in shoot_dirs:
		if Input.is_action_pressed(shoot_dir):
			released = false
			release_time = 0
			current_shoot_dir = input_to_dir.get(shoot_dir)
			
			_grow_time += delta
			if current_projectile and _grow_time <= time_to_full_bubble:
				if  not $InflateAudioPlayer.playing:
					$InflateAudioPlayer.play(0.27)
				current_projectile.global_scale = lerp(start_scale, max_scale, _grow_time / time_to_full_bubble)
				#current_projectile.global_scale += Vector2.ONE * 0.01
				break
			
			# Detect holding bubble too long
			if current_projectile and _grow_time >= time_to_full_bubble:

				if not is_tweening:
					_tween = get_tree().create_tween().set_loops(2)
					is_tweening = true
					_tween.tween_property(current_projectile.sprite, "self_modulate:a", 0.0, 0.15)
					_tween.tween_property(current_projectile.sprite, "self_modulate:a", 0.75, 0.15).from(0.0)
					_tween.tween_callback(func(): _clear_tween())
				_time_with_full_bubble += delta
				if _time_with_full_bubble >= time_before_bubble_pop:
					pop_bubble()
					
			
			if not current_projectile and num_bullets > 0:
				# Player holding down after projectiel died
				_create_bubble()
	
	for shoot_dir in shoot_dirs:
		if input_to_dir.get(shoot_dir) == current_shoot_dir and Input.is_action_just_released(shoot_dir):
			if Time.get_unix_time_from_system() - last_pressed_timestamp > 0.05:
				# This code path is to handle quickly shooting small projectiles
				_let_go()
				released = false
				release_time = 0
				last_pressed_timestamps = [0.0, 0.0, 0.0, 0.0]
			else:
				# Start a timer to release this bubble shortly.
				# It's to avoid a case where the player switches shoot direction, so there's a small gap in time
				# where all keys are released.
				released = true


func _create_bubble() -> void:
	if _can_create_bubble:
		var _new_bubble: Bubble = ProjectileScene.instantiate()
		_new_bubble.scale = start_scale
		current_projectile = _new_bubble
		current_projectile.player = get_parent()
		current_projectile.on_disappear.connect(on_bubble_disappear, CONNECT_ONE_SHOT)
		current_projectile.on_bounce.connect($BoingPlayer.play)
		_grow_time = 0.0
		add_child(current_projectile)
		num_bullets -= 1

func _clear_tween() -> void:
	if _tween:
		_tween.stop()
	is_tweening = false
	if current_projectile:
		current_projectile.sprite.self_modulate.a = 0.75

func _let_go() -> void:
	_clear_tween()
	if current_projectile:
		_time_with_full_bubble = 0.0
		#todo: use current dir
		current_projectile.dir = current_shoot_dir
		current_projectile.inflate_percent = current_projectile.scale.length() / max_scale.length()
		current_projectile.reparent(get_parent().get_parent())
		current_projectile.release()
		current_projectile = null
		$InflateAudioPlayer.stop()
		$SpitPlayer.play()

func pop_bubble() -> void:
	_time_with_full_bubble = 0.0
	bubble_popped.emit()
	_can_create_bubble = false
	get_tree().create_timer(0.5).timeout.connect(func(): _can_create_bubble=true)
	# todo: play pop animation
	current_projectile.queue_free()
	$PopAudioPlayer.play()
	$InflateAudioPlayer.stop()
	current_projectile = null

func on_bubble_disappear():
	if indicator:
		num_bullets += 1
	
	if is_inside_tree():
		$PopAudioPlayer.play()

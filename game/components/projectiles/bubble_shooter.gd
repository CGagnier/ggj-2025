extends Node2D

signal bubble_popped
signal bubble_created
signal bubble_shot

@export_category("General")
@export var projectile_speed := 0.0
@export var ProjectileScene: PackedScene
@export var bubbles_can_absorb = true

@export_category("Static")
@export var is_static: bool = false
@export var static_shoot_dir: Vector2 = Vector2.RIGHT
@export var shoot_delay := 0.0

## Set this to the owner of the bubble shooter to avoid the bubble colliding with it.
@export var shooter_ref: Node2D = null

@export_category("Dynamic")
@export var start_scale = Vector2(0.5, 0.5)
@export var max_scale: Vector2 = Vector2(2,2)
@export var growth_rate := 1.0
@export var indicator: BubbleIndicator
@export var time_before_bubble_pop := 0.5
## How long you can hold a 'full' bubble before it pops
@export var time_to_full_bubble := 1.0


@onready var _current_bullets = 3 if not is_static else 9999

var is_tweening = false
var _tween = null
#
var _grow_time := 0.0

var current_projectile: Node2D = null

const shoot_dirs = ["shoot_left", "shoot_up", "shoot_right", "shoot_down"]
const move_dirs = ["move_left", "move_up", "move_right", "move_down"]

var last_pressed_timestamps = [0.0, 0.0, 0.0, 0.0]
var last_pressed_timestamp = -1
var _time_with_full_bubble := 0.0
var _can_create_bubble = true
var _last_pressed_input = Vector2.RIGHT

var num_bullets:
	set(val):
		_current_bullets = val
		if indicator:
			indicator.num_gums = val
	get:
		return _current_bullets
		
func get_input_to_dir(input) -> Vector2:
	if Settings.control_scheme == GameSettings.ControlScheme.WasdAndSpaceToShoot:
		match input:
			move_dirs[0]: return Vector2.LEFT
			move_dirs[1]: return Vector2.UP
			move_dirs[2]: return Vector2.RIGHT
			move_dirs[3]: return Vector2.DOWN
	else:
		match input:
			shoot_dirs[0]: return Vector2.LEFT
			shoot_dirs[1]: return Vector2.UP
			shoot_dirs[2]: return Vector2.RIGHT
			shoot_dirs[3]: return Vector2.DOWN
	
	return Vector2.RIGHT

#func has_input_shooting():
	#if Settings.control_scheme == GameSettings.ControlScheme.WasdAndSpaceToShoot:
		#return Input.is_action_just_pressed(shoot_dir) and not current_projectile
#
#func is_shoot_action_just_pressed():
		#if Settings.control_scheme == GameSettings.ControlScheme.WasdAndSpaceToShoot:
			#return Input.is_action_just_pressed(shoot_dir)


var current_shoot_dir = Vector2.RIGHT

var release_time := 0.0
var released = false
var release_to_let_go_time := 0.1

func ready():
	if is_static:
		_can_create_bubble = false
		await get_tree().create_timer(shoot_delay).timeout
		_can_create_bubble = false

func _process(_delta: float) -> void:
	var offset = 10 * current_shoot_dir
	if current_projectile:
		current_projectile.position = offset
		current_projectile.dir = current_shoot_dir
		current_projectile.inflate_percent = current_projectile.global_scale.length() / max_scale.length()
	
func _physics_process(delta: float) -> void:
	if released:
		release_time += delta
		
		if release_time >= release_to_let_go_time:
			_let_go()
	
	last_pressed_timestamp = -1
	if not is_static:
		_process_start_shoot(delta)
		_process_currently_shooting(delta)
		_process_release_shoot(delta)
	else:
		_process_currently_shooting_static(delta)	

### Processor for the static version of the shooter
func _process_currently_shooting_static(delta):	
	current_shoot_dir = static_shoot_dir
	if current_projectile and _grow_time <= time_to_full_bubble:
		if not $InflateAudioPlayer.playing:
			$InflateAudioPlayer.play(0.27)
		current_projectile.global_scale = lerp(start_scale, max_scale, _grow_time / time_to_full_bubble)
	
	# Detect holding bubble too long
	if current_projectile and _grow_time >= time_to_full_bubble:
		if not is_tweening:
			_tween = current_projectile.create_tween().set_loops(2)
			is_tweening = true
			_tween.tween_property(current_projectile.sprite, "self_modulate:a", 0.0, 0.10)
			_tween.tween_property(current_projectile.sprite, "self_modulate:a", 0.75, 0.10).from(0.0)
			_tween.tween_callback(_clear_tween)
			
		_time_with_full_bubble += delta
		
		if _time_with_full_bubble >= time_before_bubble_pop:
			_let_go()
			
	
	if not current_projectile and num_bullets > 0:
		# Player holding down after projectile was shot
		_create_bubble()
	
	_grow_time += delta

func _process_start_shoot(delta):
	if Settings.control_scheme == GameSettings.ControlScheme.WasdAndSpaceToShoot:
		var _any_dir_set = false
		for move_dir in move_dirs:
			if Input.is_action_just_pressed(move_dir):
				_any_dir_set = true
				_last_pressed_input = move_dir
		
		if Input.is_action_just_pressed("shoot") and not current_projectile and num_bullets > 0:
			if not _any_dir_set:
				# In case player shoots while standing still, make him shoot the way he's facing
				current_shoot_dir = get_input_to_dir(_last_pressed_input)
			_create_bubble()
	else:
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

func _process_currently_shooting(delta):
	var is_inflating = false
	if Settings.control_scheme == GameSettings.ControlScheme.WasdAndSpaceToShoot:
		if Input.is_action_pressed("shoot"):
			released = false
			is_inflating = true
			for move_dir in move_dirs:
				if Input.is_action_pressed(move_dir):
					current_shoot_dir = get_input_to_dir(move_dir)
	else:
		for shoot_dir in shoot_dirs:
			if Input.is_action_pressed(shoot_dir):
				released = false
				is_inflating = true
				current_shoot_dir = get_input_to_dir(shoot_dir)
	
	if is_inflating:
		_grow_time += delta
		release_time = 0
		
		if current_projectile and _grow_time <= time_to_full_bubble:
			if not $InflateAudioPlayer.playing:
				$InflateAudioPlayer.play(0.27)
			current_projectile.global_scale = lerp(start_scale, max_scale, _grow_time / time_to_full_bubble)
		
		# Detect holding bubble too long
		if current_projectile and _grow_time >= time_to_full_bubble:
			if not is_tweening:
				_tween = current_projectile.create_tween().set_loops(2)
				is_tweening = true
				_tween.tween_property(current_projectile.sprite, "self_modulate:a", 0.0, 0.10)
				_tween.tween_property(current_projectile.sprite, "self_modulate:a", 0.75, 0.10).from(0.0)
				_tween.tween_callback(_clear_tween)
			_time_with_full_bubble += delta
			if _time_with_full_bubble >= time_before_bubble_pop:
				pop_bubble()
				
		
		if not current_projectile and num_bullets > 0:
			# Player holding down after projectile was shot
			_create_bubble()
				
func _process_release_shoot(delta):
	if Settings.control_scheme == GameSettings.ControlScheme.WasdAndSpaceToShoot:
		if Input.is_action_just_released("shoot"):
			_let_go()
	else:
		for shoot_dir in shoot_dirs:
			if get_input_to_dir(shoot_dir) == current_shoot_dir and Input.is_action_just_released(shoot_dir):
				if Time.get_unix_time_from_system() - last_pressed_timestamp > 0.05:
					# This code path is to handle quickly shooting small projectiles
					_let_go()
					last_pressed_timestamps = [0.0, 0.0, 0.0, 0.0]
				else:
					# Start a timer to release this bubble shortly.
					# It's to avoid a case where the player switches shoot direction, so there's a small gap in time
					# where all keys are released.
					released = true
	

func _create_bubble() -> void:
	if is_static:
		await get_tree().create_timer(shoot_delay).timeout
	
	if _can_create_bubble:
		_can_create_bubble = false
		var _new_bubble: Bubble = ProjectileScene.instantiate()
		_new_bubble.scale = start_scale
		current_projectile = _new_bubble
		current_projectile.on_disappear.connect(on_bubble_disappear, CONNECT_ONE_SHOT)
		current_projectile.on_bounce.connect(_on_bounce.bind(current_projectile))
		current_projectile.shooter = self if shooter_ref == null else shooter_ref
		current_projectile.can_absorb = bubbles_can_absorb
		_grow_time = 0.0
		add_child(current_projectile)
		num_bullets -= 1
		bubble_created.emit()

func _on_bounce(proj):
	if proj:
		$BoingPlayer.pitch_scale = 1.2 - (proj.inflate_percent*0.2)
		$BoingPlayer.play()
	
func _clear_tween() -> void:
	is_tweening = false
	if current_projectile:
		current_projectile.sprite.self_modulate.a = 0.75

func _let_go() -> void:
	# released is for debouncing key pressses when using the arrow keys to shoot
	released = false
	release_time = 0
			
	_clear_tween()
	if current_projectile:
		get_tree().create_timer(shoot_delay).timeout.connect(func(): _can_create_bubble = true)
		
		_time_with_full_bubble = 0.0
		#todo: use current dir
		current_projectile.dir = current_shoot_dir
		current_projectile.reparent(get_parent().get_parent())
		current_projectile.release()
		
		if projectile_speed != 0.0:
			current_projectile.base_speed = projectile_speed
		
		current_projectile = null
		$InflateAudioPlayer.stop()
		$SpitPlayer.play()
		bubble_shot.emit()
		
		#
		#if is_static:
			#get_tree().create_timer(shoot_delay).timeout.connect(func(): current_projectile = null)
		#else:

func pop_bubble() -> void:
	_time_with_full_bubble = 0.0
	bubble_popped.emit()
	_can_create_bubble = false
	
	_clear_tween()
	
	if is_inside_tree():
		# todo fix this somehow, causes an error
		if get_tree():
			get_tree().create_timer(0.5).timeout.connect(func(): _can_create_bubble=true)
		# todo: play pop animation
		current_projectile.queue_free()
		$PopAudioPlayer.play()
		$InflateAudioPlayer.stop()
		current_projectile = null
		

func on_bubble_disappear(popped_bubble):
	num_bullets += 1
	
	if popped_bubble == current_projectile:
		pop_bubble()
	
	if is_inside_tree():
		$PopAudioPlayer.play()

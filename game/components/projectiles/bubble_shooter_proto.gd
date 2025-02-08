extends Node2D

signal bubble_popped
signal bubble_created
signal bubble_shot

@export_category("General")
@export var projectile_speed := 0.0
@export var ProjectileScene: PackedScene
@export var bubbles_can_absorb = true
@export var bubble_shoot_cooldown = 0.3

@export_category("Static")
@export var is_static: bool = false
@export var static_shoot_dir: Vector2 = Vector2.RIGHT
@export var shoot_delay := 0.0

## Set this to the owner of the bubble shooter to avoid the bubble colliding with it.
@export var shooter_ref: Node2D = null


@export_category("Dynamic")
## How the bubble should behave
@export var bubble_definition: BubbleDefinition
@export var start_scale = Vector2(0.5, 0.5)
@export var max_scale: Vector2 = Vector2(2,2)
@export var growth_rate := 1.0
@export var indicator: BubbleIndicator
@export var time_before_bubble_pop := 0.5
## How long you can hold a 'full' bubble before it pops
@export var time_to_full_bubble := 1.0


@onready var _current_bullets = 3 if not is_static else 9999
#
var _grow_time := 0.0

var current_projectile: Node2D = null

const shoot_dirs = ["shoot_left", "shoot_up", "shoot_right", "shoot_down"]
const move_dirs = ["move_left", "move_up", "move_right", "move_down"]

var bubble_initial_alpha = 0.75

var last_pressed_timestamps = [0.0, 0.0, 0.0, 0.0]
var last_pressed_timestamp = -1
var _time_with_full_bubble := 0.0
var _can_create_bubble = true
var _last_pressed_input = Vector2.RIGHT

const BUBBLE_BLINK_ALPHA = 0.5

class InflateStateMachine extends Node:
	
	## The time to scale the bubble to its maximum size when we enter a new state
	const INFLATE_TIME := 0.4
	var alpha_tween = null
	var bubble_definition = null
	
	var _bubble_initial_alpha = 0.75
	var _state_index := -1
	var _time_in_inflate_state := 0.0
	var _shooter_ref = null
	var _scale_tween: Tween
	
	@onready var audio_player = _shooter_ref.get_node("InflateAudioPlayer")
	@onready var warning_player = _shooter_ref.get_node("WarningPlayer")
	
	var num_states:
		get:
			return bubble_definition.num_states
	
	var current_bubble_value:
		get:
			return _state_index + 1
			# We could eventually assign bullet values in the bubble resource itself if we had need for it.
			#return bubble_definition.get_state(_state_index).bullet_value
	
	func _init(_bubble_def: BubbleDefinition, bubble_shooter):
		bubble_definition = _bubble_def
		_shooter_ref = bubble_shooter
		
	func reset():
		if alpha_tween:
			alpha_tween.kill()
			alpha_tween = null
			
		_state_index = -1
		_time_in_inflate_state = 0.0
		warning_player.stop()
	
	func get_current_bubble_state():
		return bubble_definition.get_state(_state_index)
		
	func _transition_to_next_state():
		# Handle state transition
		_time_in_inflate_state = 0.0
		_state_index += 1
		
		if _state_index == bubble_definition.num_states:
			# Entered last state
			_shooter_ref.pop_bubble()
			reset()
		else:
			#print("Transitioning to state %d" % _state_index)
			var next_state:InflateState = bubble_definition.get_state(_state_index)
			audio_player.pitch_scale = next_state.audio_pitch_scale
			_scale_tween = get_tree().create_tween()
			var property_tweener =_scale_tween.tween_property(_shooter_ref.current_projectile, "global_scale", Vector2.ONE * next_state.max_scale, INFLATE_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
				
			#property_tweener.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
			if _state_index == 0:
				property_tweener.from(Vector2.ZERO)
				
			audio_player.play()
			_shooter_ref.current_projectile.bullet_value = current_bubble_value
			_shooter_ref.num_bullets -= 1
			# Play warning sound when you're about to pop the bubble.
		
	func process_current_state():
		var state = bubble_definition.get_state(bubble_definition.num_states -1)
			
		# Flash bubble during last state
		if not alpha_tween:
			const blink_duration = 0.15
			var num_blinks = floor(state.state_time / blink_duration)
			var bubble_sprite = _shooter_ref.current_projectile.sprite
			_bubble_initial_alpha = bubble_sprite.self_modulate.a
			
			alpha_tween = get_tree().create_tween().set_loops(num_blinks)
			alpha_tween.tween_property(bubble_sprite, "self_modulate:a", BUBBLE_BLINK_ALPHA, blink_duration)
			alpha_tween.tween_property(bubble_sprite, "self_modulate:a", _bubble_initial_alpha, blink_duration).from(0.0)
		
		if not warning_player.is_playing() and _state_index == num_states - 1 and _time_in_inflate_state > state.state_time / 3.0:
			pass # Revisit this
			#warning_player.play()
	
	func process(delta: float):
		if not _shooter_ref.current_projectile: return
		if _state_index == -1 and _shooter_ref.current_projectile:
			_transition_to_next_state()
		
		if _state_index == bubble_definition.num_states - 1:
			process_current_state()
	
		_time_in_inflate_state += delta
		
		if _time_in_inflate_state >= bubble_definition.get_state(_state_index).state_time:
			if _shooter_ref.num_bullets:
				_transition_to_next_state()	
		

@onready var inflate_state_machine:InflateStateMachine = InflateStateMachine.new(bubble_definition, self)
	
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

var current_shoot_dir = Vector2.RIGHT

var release_time := 0.0
var released = false
var release_to_let_go_time := 0.1

func _ready():
	add_child(inflate_state_machine)
	
	if is_static:
		_can_create_bubble = false
		await get_tree().create_timer(shoot_delay).timeout
		_can_create_bubble = false

func _process(delta: float) -> void:
	var projectile_offset = current_projectile.scale if current_projectile else Vector2.ONE
	var offset = 10 * get_input_to_dir(_last_pressed_input) * projectile_offset * 1.5
	if current_shoot_dir.y == 0:
		# Move bubble down when you're aiming horizontally to make it easier to jump on bubble.
		offset.y += 2 * projectile_offset.length()
	
	inflate_state_machine.process(delta)
	$ShooterOffset.target_position = to_global(offset)
	
	if current_projectile:
		# Move the bubble towards our 'spring arm' so that we can't spawn bubbles in walls 
		current_projectile.global_position = $ShooterOffset.corrected_position
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
		pass
		#current_projectile.global_scale = lerp(start_scale, max_scale, _grow_time / time_to_full_bubble)
	
	if not current_projectile and num_bullets > 0:
		# Player holding down shoot button after projectile was shot
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
	else:
		for shoot_dir in shoot_dirs:
			if Input.is_action_pressed(shoot_dir):
				released = false
				is_inflating = true
	
	current_shoot_dir = get_input_to_dir(_last_pressed_input) 
	
	if is_inflating:
		_grow_time += delta
		release_time = 0
			
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
		current_projectile.shooter = self if shooter_ref == null else shooter_ref
		current_projectile.can_absorb = bubbles_can_absorb
		_grow_time = 0.0
		$ShooterOffset.add_child(current_projectile)
		bubble_created.emit()

func _let_go() -> void:
	# released is for debouncing key pressses when using the arrow keys to shoot
	released = false
	release_time = 0
	
	if current_projectile:
		get_tree().create_timer(shoot_delay).timeout.connect(func(): _can_create_bubble = true)
		
		_time_with_full_bubble = 0.0
		
		var current_bubble_state = inflate_state_machine.get_current_bubble_state()
		
		current_projectile.sprite.self_modulate.a = bubble_initial_alpha
		current_projectile.dir = current_shoot_dir
		
		#todo: Just give the resource to the bubble.
		current_projectile.base_speed = projectile_speed if projectile_speed != 0.0 else current_bubble_state.speed
		current_projectile.can_absorb = bubbles_can_absorb and current_bubble_state.can_absorb
		current_projectile.impact_force = current_bubble_state.impact_force
		
		current_projectile.reparent(get_parent().get_parent())
		current_projectile.release()
		
		current_projectile = null
		$InflateAudioPlayer.stop()
		$SpitPlayer.play()
		bubble_shot.emit()
	
	inflate_state_machine.reset()
	

func pop_bubble() -> void:
	_time_with_full_bubble = 0.0
	bubble_popped.emit()
	_can_create_bubble = false
	
	if is_inside_tree():
		inflate_state_machine.reset()
		
		get_tree().create_timer(shoot_delay).timeout.connect(func(): _can_create_bubble=true)
		# todo: play pop animation
		current_projectile.queue_free()
		$PopAudioPlayer.play()
		$InflateAudioPlayer.stop()
		current_projectile = null
		

func on_bubble_disappear(popped_bubble):
	if is_inside_tree():
		$PopAudioPlayer.play()
		get_tree().create_timer(popped_bubble.give_bullet_back_delay).timeout.connect(give_bullet_back.bind(popped_bubble.bullet_value))
	
	if popped_bubble == current_projectile:
		pop_bubble()
	
	

func give_bullet_back(bullet_value):
	num_bullets += bullet_value

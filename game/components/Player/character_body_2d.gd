extends CharacterBody2D
class_name Player

signal died()

@export var SPEED = 160.0
@export var SPEED_JUMPDOWN = 400.0
const JUMP_VELOCITY = -360.0
@export var can_ground_pound = false

@export var max_downwards_velocity = 400
@export var max_upwards_velocity = 1000
@export var ghost_scene: PackedScene

var alive = true
var is_ground_pounding = false

## State Machine
enum state {idle, run, jump, falling, landing, hit, die, exiting_level}
var current_state = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var shooter = $Shooter
@onready var collisionshape = $CollisionShape2D


var _last_velocities = []
var _running_average_length := 5
var _last_grounded_time := 0.0
## How many frames after being grounded can the player jump (Helps jumping upon leaving platforms)
const frames_to_jump_after_grounded = 7

var _is_exiting_level = false
var _exiting_door: Door = null

func mean(accum, number):
	return accum + number / _running_average_length
	
var recent_velocity:
	get:
		return _last_velocities.reduce(mean, Vector2.ZERO)

class Impulse extends RefCounted:
	var impulse_velocity: Vector2
	var damping_factor := 0.95
	var done:
		get:
			return impulse_velocity == Vector2.ZERO
	
	func _init(_dir, damp: float = 0.95):
		impulse_velocity = _dir
		damping_factor = damp
	
	func process(delta: float):
		var val = impulse_velocity
		impulse_velocity *= damping_factor
		
		if impulse_velocity.length() < 4:
			impulse_velocity = Vector2.ZERO
		
		return val
		
var impulses:Array[Impulse] = []

func add_impulse(impulse: Vector2, damp = 0.95):
	impulses.push_back(Impulse.new(impulse, damp))

#region Statess
func _enter_state(new_state):
	if new_state == current_state:
		return
	
	if current_state == state.exiting_level:
		return
	
	if current_state == state.die:
		if Settings.debug:
			print("Can't enter state %s since player is dying" % state.keys()[new_state])
		return
	
	if Settings.debug:
		print('Entering state %s' % state.keys()[new_state])
		
	_leave_state(current_state)
	var last_state = current_state
	current_state = new_state
	
	if new_state == state.run:
		animated_sprite.play("run")
		if not $Footstep2.playing:
			$Footstep2.play()
	if new_state == state.jump:
		is_ground_pounding = false
		velocity.y = JUMP_VELOCITY
		$JumpSound.play(0.1)
		animated_sprite.play("jump")
	if new_state == state.idle:
		animated_sprite.play("idle")
	if new_state == state.falling:
		animated_sprite.play("falling")
	if new_state == state.landing:
		#$Footstep2.play()
		animated_sprite.play("landing")
	if new_state == state.die:
		animated_sprite.play("die")
		_enter_dead_state.call_deferred()
	if new_state == state.exiting_level:
		velocity.x = 0
		$ExitChime.play()
		# Reparent since player is getting destroyed.
		$ExitChime.reparent(get_parent())
		$Shooter.queue_free()
		

# The good, the bad and the ugly
func _try_change_state(new_state):
	
	# if falling, jump, landing, can't run
	# if falling, jump, landing, can't idle
	# if jump, landing, can't falling
	match new_state:
		state.run: # or state.idle or state.falling
			if not (current_state == state.falling or current_state == state.jump or current_state == state.landing):
				_enter_state(new_state)
		state.idle:
			if not (current_state == state.falling or current_state == state.jump or current_state == state.landing):
				_enter_state(new_state)
		state.falling:
			if not (current_state == state.falling or current_state == state.jump or current_state == state.landing):
				_enter_state(new_state)

func _process_states():
	if(current_state == state.falling):
		_process_falling()
	if(current_state == state.jump):
		_process_jumping()

func _leave_state(_old_state):
	pass
	
func _process_falling():
	if is_on_floor():
		_enter_state(state.landing)
	

func _process_jumping():
	if velocity.y >= 0:
		_enter_state(state.falling)

#endregion

func _ready() -> void:
	alive = true
	_enter_state(state.idle)
	$Shooter.bubble_popped.connect(_on_bubble_popped)
	$Shooter.bubble_absorbed.connect(_on_entity_absorbed)
	$Footstep2.finished.connect(_finished_sound)

func _finished_sound():
	if current_state != state.run:
		$Footstep2.stop()
	else:
		$Footstep2.play()

func _process_impulses(delta):
	var applied_force := Vector2.ZERO
	
	var to_remove = []
	for i in impulses.size():
		var impulse = impulses[i]
		applied_force += impulse.process(delta)
		
		if impulse.done:
			to_remove.push_back(i)
	
	for index in to_remove:
		impulses.remove_at(index)
	
	return applied_force

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_last_grounded_time = Time.get_ticks_msec()

	# Add the gravity.
	if not is_on_floor():
		var input_down := Vector2(0,Input.get_action_strength("move_down")*SPEED_JUMPDOWN)
		
		if abs(velocity.y) > 90:
			# Only allow ground pound if you're at the apex of your jump
			input_down = Vector2.ZERO
		
		if not can_ground_pound: input_down = Vector2.ZERO
		if input_down.length() > 0:
			is_ground_pounding = true
		
		velocity += get_gravity() * delta + input_down
		
		if current_state == state.exiting_level:
			# Get that lil guy to the ground.
			if velocity.y > 0:
				velocity.y += 2000 * delta
			else:
				velocity *= 0.5
			
		#velocity.y = clampf(velocity.y, -max_upwards_velocity, max_downwards_velocity)
		
		# Not falling in the context of a jump
		if alive:
			_try_change_state(state.falling)
	
	if alive and current_state != state.exiting_level:
		# Handle jump.
		if InputBuffer.is_action_press_buffered("jump") and _was_on_floor():
			_enter_state(state.jump)
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("move_left", "move_right")

		if direction:
			velocity.x = direction * SPEED
			# Face walking direction
			animated_sprite.flip_h = direction > 0
			var _mult = -1 if animated_sprite.flip_h else 1
			$ExpressionHolder.scale.x = _mult
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		velocity += _process_impulses(delta)

		if velocity.y == 0:
			if velocity.x != 0.0 :
				_try_change_state(state.run)
			else:
				_try_change_state(state.idle)

		_process_states()
		
		_last_velocities.push_back(velocity)
		if _last_velocities.size() > _running_average_length: _last_velocities.pop_front()
	
	# Allow the Player to reach it's final rest in peace <3
	elif not collisionshape.disabled:
		if round(velocity.y) == 0:
			collisionshape.set_deferred("disabled", true)
		
	if not collisionshape.disabled:
		move_and_slide()
	
	
	# When exiting level, make sure to start the animation when the player is grounded.
	if current_state == state.exiting_level and is_on_floor() and not _is_exiting_level:
		_is_exiting_level = true
		
		# Turn the player to face the door's center
		if _exiting_door.global_position.x < global_position.x:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
		
		LevelManager.exit_current_level(self)
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "landing":
		_enter_state(state.idle)
	if animated_sprite.animation == "die":
		died.emit()

func _dying() -> void:
	_enter_state(state.die)
	

func _enter_dead_state():
	alive = false
	
	$DieSound.play()
	var level_persistent_entities = LevelManager.current_level.get_node("PersistentEntities")
	
	reparent(level_persistent_entities)
	var ghost = ghost_scene.instantiate()
	level_persistent_entities.add_child(ghost)
	ghost.global_position = global_position - Vector2(2, 10)
	
	set_collision_layer_value(2, 0)
	set_collision_mask_value(2, 0)
	
	$ExpressionHolder/Expression.play_wtf()
	$BubbleIndicator.hide()
	if shooter:
		shooter.queue_free()
	var _tween = get_tree().create_tween()
	_tween.tween_property(animated_sprite, "self_modulate:a", 0.7, 0.5)
	remove_from_group("Player")

func _on_bubble_popped():
	$ExpressionHolder/Expression.play_wtf()

func _was_on_floor():
	var time_now = Time.get_ticks_msec()
	var delta = time_now - _last_grounded_time
	var num_frames = delta / 16.66666
	return num_frames <= frames_to_jump_after_grounded
	
func _on_entity_absorbed(entity):
	add_collision_exception_with(entity)


func _on_player_feet_area_entered(area: Area2D) -> void:
	if area.owner is Door and area.owner.is_exit:
		_exiting_door = area.owner
		_enter_state(state.exiting_level)

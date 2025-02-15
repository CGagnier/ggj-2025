extends CharacterBody2D
class_name Player

signal died()

@export var SPEED = 160.0
@export var AIR_SPEED_INFLUENCE := 5.0
@export var SPEED_JUMPDOWN = 400.0
const JUMP_VELOCITY = -360.0
@export var can_ground_pound = false
@export var AIR_RESISTANCE := 10.0
@export var GROUND_FRICTION := 15.0

@export var MAX_AIR_SPEED_INFLUENCE = 5.0

@export var max_downwards_velocity = 400
@export var max_upwards_velocity = 1000
@export var ghost_scene: PackedScene

var alive = true
var is_ground_pounding = false

## State Machine
enum state {idle, run, jump, pre_bounce, bouncing, falling, landing, hit, die, exiting_level}
var current_state = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var shooter = $Shooter
@onready var collisionshape = $CollisionShape2D

#region player_control
var air_gravity_multiplier := 1.0
var _player_air_speed = 0.0
var _applied_ground_speed = false
var _last_velocities = []
var _running_average_length := 5
var _last_grounded_time := 0.0
## How many frames after being grounded can the player jump (Helps jumping upon leaving platforms)
const frames_to_jump_after_grounded = 7
#endregion

var _is_exiting_level = false
var _exiting_door: Door = null

# The velocity required to start falling after hovering into the air for a few frames.
const _jump_stop_velocity_ = -10.0

#region bouncing_stuff
### Bouncing stuff
# How many frames should we stay in the pre_bounce state on a static bubble
const _pre_bounce_frames = 4
# How many frames should we stay in pre_bounce on a dynamic bubble
const _pre_bounce_frame_dynamic = 7
# How many frames before we allow the player to move in the air after boucning.
#endregion

const _bouncing_frames = 2

class BounceInfo extends RefCounted:
	var _frames_in_state = 0
	var bubble: Bubble = null
	var _velocity_upon_collision := 0.0
	var _bubble_offset: float = 0.0
	
	# Super jump shit
	var _attempted_super_jump = false
	var _frames_holding_right = 0
	var _frames_holding_left = 0

var bounce_info: BounceInfo = null

func mean(accum, number):
	return accum + number / _running_average_length
	
var recent_velocity:
	get:
		return _last_velocities.reduce(mean, Vector2.ZERO)

var last_velocity:
	get:
		return _last_velocities.back() if _last_velocities.size() else Vector2.ZERO

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
	
	if current_state == state.pre_bounce:
		if new_state	 != state.exiting_level and new_state != state.die and new_state != state.bouncing:
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
		# Note: This wil be accelerated in the process
		air_gravity_multiplier = 0.15
		animated_sprite.play("falling")
	if new_state == state.landing:
		#$Footstep2.play()
		animated_sprite.play("landing")
	if new_state == state.die:
		animated_sprite.play("die")
		_enter_dead_state.call_deferred()
	if new_state == state.bouncing:
		air_gravity_multiplier = 1.2
		_enter_bouncing_state()
	if new_state == state.exiting_level:
		velocity.x = 0
		$ExitChime.play()
		# Reparent since player is getting destroyed.
		$ExitChime.reparent(get_parent())
		$Shooter.queue_free()
		

func bounce(bubble: Bubble):
	_try_change_state(state.pre_bounce)
	# Todo : Play a pre-bounce sound
	bounce_info = BounceInfo.new()
	bounce_info.bubble = bubble
	bounce_info.bubble.can_die = false
	bounce_info._velocity_upon_collision = velocity.y
	bounce_info._bubble_offset = bubble.global_position.x - global_position.x

# The good, the bad and the ugly
func _try_change_state(new_state):
	
	if current_state == state.pre_bounce:
		if new_state != state.bouncing:
			return
		else:
			_enter_state(state.bouncing)
	
	if current_state == state.bouncing:
		# Only allow the bouncing state to transition to something else
		return
	
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
		_:
			_enter_state(new_state)
		
func _process_states(delta):
	match current_state:
		state.falling:
			_process_falling()
		state.jump:
			_process_jumping()
		state.pre_bounce:
			_process_pre_bounce(delta)
		state.bouncing:
			_process_bouncing(delta)
		state.exiting_level:
			_process_exiting_level(delta)
			

func _leave_state(_old_state):
	if _old_state == state.pre_bounce:
		pass
		#_frames_in_state = 0
		#_failed_super_jump = false
	
	if _old_state == state.bouncing:
		air_gravity_multiplier = 1.0
		if bounce_info.bubble:
			bounce_info.bubble.finish_bouncing(self)
		
		bounce_info = null
	
	if _old_state == state.falling:
		air_gravity_multiplier = 1.0
	
func _process_falling():
	air_gravity_multiplier = move_toward(air_gravity_multiplier, 1.2, 0.8)
	if is_on_floor():
		_enter_state(state.landing)
	
func _process_jumping():
	if velocity.y >= -10:
		_enter_state(state.falling)
		
func _process_pre_bounce(delta: float):
	if Input.is_action_pressed("move_left"):
		bounce_info._frames_holding_left +=1 
	elif Input.is_action_pressed("move_right"):
		bounce_info._frames_holding_right += 1
	
	bounce_info._frames_in_state += 1
	velocity = Vector2.ZERO
	
	if bounce_info.bubble:
		global_position.x = bounce_info.bubble.global_position.x - bounce_info._bubble_offset
	
	position.y += 0.5
	
	var state_frame_duration = _pre_bounce_frames if bounce_info.bubble.is_static else _pre_bounce_frame_dynamic
	if not bounce_info.bubble.is_static and not bounce_info.bubble.launched:
		state_frame_duration = 1
		
	if bounce_info._frames_in_state == state_frame_duration:
		_try_change_state(state.bouncing)

func _process_bouncing(delta: float):
	if bounce_info._frames_in_state == _bouncing_frames:
		_enter_state(state.falling)
		return
		
	bounce_info._frames_in_state += 1

func _process_exiting_level(delta: float):
	var force_exit_level = false
	if not is_on_floor():
		# if the player comes from below the door, make sure he can't fall while doing the animation
		if global_position.y > _exiting_door.global_position.y:
			air_gravity_multiplier = 0.
			var door_position = _exiting_door.global_position.y
			
			global_position.y = move_toward(global_position.y, door_position, 1)
			if abs(door_position - global_position.y) < 5:
				print('force-exit')
				force_exit_level = true
				
			velocity.y = 0
		else:
			# Get that lil guy to the ground.
			if velocity.y > 0:
				velocity.y += 2000 * delta
			else:
				velocity *= 0.5
					
			#global_position.y = min(global_position.y, _exiting_door.global_position.y)
	
	# When exiting level, make sure to start the animation when the player is grounded.
	if (is_on_floor() or force_exit_level) and not _is_exiting_level:
		_is_exiting_level = true
		
		# Turn the player to face the door's center
		if _exiting_door.global_position.x < global_position.x:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
		
		LevelManager.exit_current_level(self)

func _enter_bouncing_state():
	#print("Left %d Right %d" % [bounce_info._frames_holding_left, bounce_info._frames_holding_right])
	
	var super_jumping = InputBuffer.is_action_press_buffered("jump", 150)
	
	# Reset frame counter for duration
	bounce_info._frames_in_state = 0
	
	var bounce_dir = Vector2(0,-1)
	var super_jump_force = Vector2.ZERO
	
	var bubble =  bounce_info.bubble
	var is_quick = bubble.launched and bubble.stage == 0 and not bubble.has_collided
	
	var bubble_jump_force = bounce_info.bubble.jump_force
	if is_quick:
		bubble_jump_force *= 1.5
	
	if super_jumping:
		if bounce_info._frames_holding_left >= 6:
			## TODO: two possible angles depending on how long
			#super_jump_force = Vector2.LEFT.rotated(deg_to_rad(45))
			super_jump_force = Vector2.LEFT * bubble_jump_force
		elif bounce_info._frames_holding_right >= 6:
			#super_jump_force = Vector2.RIGHT.rotated(-deg_to_rad(45))
			super_jump_force = Vector2.RIGHT * bubble_jump_force
		else:
			super_jump_force = Vector2(0, -1.5) * bubble_jump_force / 5
		
		$SuperBoingPlayer.play()
	
		
	# If the player falls from super high on a bubble, we want to jump him as high with a slight dampening
	const dampen_ratio = 0.9
	var dampened_velocity = dampen_ratio * bounce_info._velocity_upon_collision
	var bounce_factor = 1.5 # todo: use bubble jump force and scale
	# Min since negative velocity
	var bounce_velocity = max(dampened_velocity, bounce_info.bubble.jump_force)
	#velocity.y = bounce_dir * bounce_velocity
	
	velocity = bounce_velocity * bounce_dir + super_jump_force
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
		_player_air_speed = 0.0
		_applied_ground_speed = false

	# Add the gravity.
	if not is_on_floor():
		var actual_gravity = air_gravity_multiplier * get_gravity()
		velocity += actual_gravity * delta
		
		# Not falling in the context of a jump
		if alive:
			_try_change_state(state.falling)
	
	if alive:
		# Handle jump.
		if InputBuffer.is_action_press_buffered("jump") and _was_on_floor():
			_enter_state(state.jump)
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("move_left", "move_right")

	
		# TODO: if on the ground, allow timing jumps to go quickly?
		if is_on_floor():
			velocity.x = direction * SPEED
		else:
			## Accelerate player up to a certain point
			if _was_on_floor() and sign(direction) == sign(last_velocity.x) and not _applied_ground_speed:
				# If the player was grounded, use his previous velocity
				# Might reuse this for bounce
				_player_air_speed = abs(last_velocity.x)
				# Make sure not to apply this twice since was_on_floor returns true for a few frames.
				_applied_ground_speed = true
			else:
				_player_air_speed += AIR_SPEED_INFLUENCE
				_player_air_speed = min(_player_air_speed, MAX_AIR_SPEED_INFLUENCE)
				
			var player_influence = direction * _player_air_speed
			var max_speed = 200
			
			if direction != 0:
				if abs(velocity.x + player_influence) < max_speed:
					velocity.x += player_influence
				
			#velocity.x = clampf(velocity.x, -450, 450)
			
		# Face walking direction
		if direction != 0:
			animated_sprite.flip_h = direction > 0
		
		var _mult = -1 if animated_sprite.flip_h else 1
		$ExpressionHolder.scale.x = _mult
		
		var friction = AIR_RESISTANCE if not is_on_floor() else GROUND_FRICTION
		velocity.x = move_toward(velocity.x, 0, friction)
		
		var test = _process_impulses(delta)
		velocity += test 

		if velocity.y == 0:
			if velocity.x != 0.0 :
				_try_change_state(state.run)
			else:
				_try_change_state(state.idle)

		_process_states(delta)
		
		### TODO: we might be able to get rid of this
		_last_velocities.push_back(velocity)
		if _last_velocities.size() > _running_average_length: _last_velocities.pop_front()
	
	# Allow the Player to reach it's final rest in peace <3
	elif not collisionshape.disabled:
		if round(velocity.y) == 0:
			collisionshape.set_deferred("disabled", true)
		
	if not collisionshape.disabled:
		move_and_slide()
	

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

extends CharacterBody2D
class_name Player

signal died()

@export var SPEED = 160.0
@export var SPEED_JUMPDOWN = 400.0
const JUMP_VELOCITY = -360.0
@export var can_ground_pound = false

@export var max_downwards_velocity = 400
@export var max_upwards_velocity = 1000


var will_die = false
var alive = true
var is_ground_pounding = false

## State Machine
enum state {idle, run, jump, falling, landing, hit, die}
var current_state = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var shooter = $Shooter
@onready var collisionshape = $CollisionShape2D

var _last_velocities = []
var _running_average_length := 5

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
	
	if (current_state != new_state):
		_leave_state(current_state)
		current_state = new_state

	if(new_state == state.run):
		animated_sprite.play("run")
	if(new_state == state.jump):
		animated_sprite.play("jump")
	if new_state == state.idle:
		animated_sprite.play("idle")
	if new_state == state.falling:
		animated_sprite.play("falling")
	if new_state == state.landing:
		animated_sprite.play("landing")
	if new_state == state.die:
		animated_sprite.play("die")

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
		if will_die:
			_dying()
		else:
			_enter_state(state.landing)
	

func _process_jumping():
	if velocity.y >= 0:
		_enter_state(state.falling)

#endregion

func _ready() -> void:
	alive = true
	will_die = false
	_enter_state(state.idle)
	$Shooter.bubble_popped.connect(_on_bubble_popped)
	
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
	# Add the gravity.
	if not is_on_floor():
		var input_down := Vector2(0,Input.get_action_strength("move_down")*SPEED_JUMPDOWN)
		
		if abs(velocity.y) > 90:
			# Only allow ground pound if you're at the apex of your jump
			input_down = Vector2.ZERO
		
		if not can_ground_pound: input_down	 = Vector2.ZERO
		if input_down.length() > 0:
			is_ground_pounding = true
		
		velocity += get_gravity() * delta + input_down
		#velocity.y = clampf(velocity.y, -max_upwards_velocity, max_downwards_velocity)
		
		# TODO: Remove dying trigger
		if velocity.y > 2000:
			will_die = true
		# Not falling in the context of a jump
		if alive:
			_try_change_state(state.falling)
	
	if alive:
		# Handle jump.
		if InputBuffer.is_action_press_buffered("jump") and is_on_floor():
			is_ground_pounding = false
			velocity.y = JUMP_VELOCITY
			$JumpSound.play(0.1)
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
		move_and_slide()
		
		_last_velocities.push_back(velocity)
		if _last_velocities.size() > _running_average_length: _last_velocities.pop_front()


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "landing":
		_enter_state(state.idle)
	if animated_sprite.animation == "die":
		died.emit()

func _dying() -> void:
	$DieSound.play()
	_enter_state(state.die)
	$ExpressionHolder/Expression.play_wtf()
	alive = false
	collisionshape.set_deferred("disabled", true)
	$BubbleIndicator.hide()
	if shooter:
		shooter.queue_free()
	var _tween = get_tree().create_tween()
	_tween.tween_property(animated_sprite, "self_modulate:a", 0.7, 0.5)

func _on_bubble_popped():
	$ExpressionHolder/Expression.play_wtf()

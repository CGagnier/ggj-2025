extends CharacterBody2D
class_name Player

signal died()

@export var SPEED = 140.0
@export var SPEED_JUMPDOWN = 2000.0
const JUMP_VELOCITY = -400.0

var will_die = false
var alive = true

## State Machine
enum state {idle, run, jump, falling, landing, hit, die}
var current_state = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var shooter = $Shooter

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

func _leave_state(old_state):
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

func _physics_process(delta: float) -> void:

	# Add the gravity.
	if not is_on_floor():
		var InputDown = Vector2(0,Input.get_action_strength("move_down")*SPEED_JUMPDOWN*delta)
		velocity += get_gravity() * delta + InputDown
		
		# TODO: Remove dying trigger
		if velocity.y > 2000:
			will_die = true
		# Not falling in the context of a jump
		if alive:
			_try_change_state(state.falling)
	
	if alive:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			_enter_state(state.jump)
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("move_left", "move_right")

		if direction:
			velocity.x = direction * SPEED
			# Face walking direction
			animated_sprite.flip_h = direction > 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		if velocity.y == 0:
			if velocity.x != 0.0 :
				_try_change_state(state.run)
			else:
				_try_change_state(state.idle)

		_process_states()
		move_and_slide()


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "landing":
		_enter_state(state.idle)
	if animated_sprite.animation == "die":
		print("died animation completed")
		died.emit()

func _dying() -> void:
	_enter_state(state.die)
	alive = false
	shooter.queue_free()
	var _tween = get_tree().create_tween()
	_tween.tween_property(animated_sprite, "self_modulate:a", 0.7, 0.5)

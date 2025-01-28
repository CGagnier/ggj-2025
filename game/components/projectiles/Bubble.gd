extends CharacterBody2D

class_name Bubble

signal on_disappear
signal on_bounce

@export var is_static = false
@export var bounce_force = 270

@export_category("Static Bubble")
@export var sine_intensity: float = 0.0

@export_category("Dynamic Bubbles")
@export var start_speed := 5.0
@export var final_speed := 4.0
@export var disappear_time: = 1.5
@export var needs_to_be_grounded_to_bounce = false

var speed = 2
var launched = false
var dir = Vector2.RIGHT
var inflate_percent := 0.0
var t := 0.0
var is_dynamic: 
	get: return not is_static

var has_collided = false
var body_started_in_bubble = false
var absorbed_entity = null
var _speed_multiplier = 1
var _min_velocity_to_bounce = 20
var _needs_grounded_to_bounce:
	get:
		return is_dynamic and needs_to_be_grounded_to_bounce

enum BounceState {
	AwaitingBounce,
	Bouncing,
	FinishedBounce	
}

var _entities_to_bounce: Dictionary[Node, BounceState]

# For not detecting collision after absorb
var _can_die = true
var _should_die_after_delay = false

var _can_play_wall_sound = true

@onready var raycast_down_left = $RaycastDownLeft
@onready var raycast_down_right = $RaycastDownRight
@onready var raycast_left = $RaycastLeft
@onready var raycast_left2 = $RaycastLeft2
@onready var raycast_right = $RaycastRight
@onready var raycast_right2 = $RaycastRight2

@onready var raycasts = [raycast_down_left, raycast_down_right, raycast_left, raycast_left2, raycast_right, raycast_right2]
@onready var downward_raycasts = [raycast_down_left, raycast_down_right]

@onready var sine_t := randf() * 10

@onready var particles = $CPUParticles2D
@onready var sprite = $Sprite2D

func _ready():

	if is_static:
		set_collision_mask_value(1, 0)
	#$HitWall.finished.connect(_on_hit_wall_played)

func _process(delta: float):
	if is_static:
		sine_t += delta
		global_position.y += sin(sine_t) * sine_intensity / 300

func _physics_process(delta: float) -> void:
	_process_bouncing(delta)
	
	if launched:
		t += delta * 2
		t = min(t, 1.0)
		
		# Activate bounce after a small delay
		speed = lerpf(start_speed, final_speed, t) * _speed_multiplier
		
		var collision = move_and_collide(dir *  speed)
		
		if collision and not has_collided:
			var collided = collision.get_collider()
			if collided is Bubble:
				play_hit_wall_sound()
				#_handle_bubble_collision(collided as Bubble)
			elif collided is Interactable:
				if not absorbed_entity:
					_handle_interactable_collision.call_deferred(collided as Interactable)
			else:
				# re-enable to bounce, this code handles killing the bubble if it contacts something
				#dir = dir.bounce(collision.get_normal())
				
				if is_static: return # Don't kill environment bubbles
				
				if collided is not Player:
					if (collision.get_normal() * dir).length() > 0:
						play_hit_wall_sound()
						_delay_die()
				
func _delay_die() -> void: 
	if _should_die_after_delay or not _can_die: return #no-op if already scheduled to die
	_speed_multiplier = 0
	_should_die_after_delay = true
	var _real_disapear_time = disappear_time if not absorbed_entity else 0.0
	await get_tree().create_timer(_real_disapear_time).timeout
	
	# Possible to be overriden by absorbing an entity
	if _should_die_after_delay:
		queue_free()

func release() -> void:
	launched = true
	for raycast in raycasts:
		raycast.global_scale = Vector2.ONE
	
	speed = start_speed
	$SafetyDestroyTimer.timeout.connect(safety_destroy)
	$SafetyDestroyTimer.start()
	
func absorb(interactable: Interactable):
	_can_die = false
	_should_die_after_delay = false
	
	absorbed_entity = interactable
	
	var tween = get_tree().create_tween()
	
	var target_position = interactable.global_position
	
	# absord method
	interactable.get_node("CollisionShape2D").disabled = true
	interactable.z_index = 0
	interactable.z_as_relative = false
	interactable.gravity_scale = 0
	$Sprite2D.self_modulate *= 0.7
	
	_speed_multiplier = 0
	
	tween.tween_property(self, "position", target_position, 0.2)#.set_delay(0.1)
	tween.tween_callback(func(): interactable.reparent(self))
	
	
	#tween.set_parallel()
	#tween.tween_property(self, "speed", 0, 0.3).set_delay(0.8)
	tween.tween_property(self, "_speed_multiplier", 1, 0.3)
	tween.tween_callback(func(): _can_die = true)

func _handle_bubble_collision(other_bubble: Bubble):
	var scene:PackedScene = load(scene_file_path)
	var new_instance = scene.instantiate()
	other_bubble.has_collided = true # prevent other bubble from detecting same collision
	other_bubble.queue_free()
	queue_free()
	
	add_sibling(new_instance)
	
	new_instance.global_position = global_position
	new_instance.scale = scale
	new_instance.start_speed = 0
	new_instance.final_speed = 0
	new_instance.launched = true
	
	var collision_tween = get_tree().create_tween()
	var target_position = (other_bubble.global_position - global_position) / 2 + global_position
	collision_tween.set_parallel()
	collision_tween.tween_property(new_instance, "global_position", target_position, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	var total_length = 0.5*(global_scale.length() + other_bubble.global_scale.length())
	collision_tween.tween_property(new_instance, "scale", Vector2(1,1) * total_length, 0.3).set_trans(Tween.TRANS_ELASTIC)

func _handle_interactable_collision(interactable: Interactable):
	absorb(interactable)
	dir = Vector2.UP

func _on_jump_pad_body_entered(body: Node2D) -> void:
	_jump_pad_entered(body)

func _on_jump_pad_body_exited(body: Node2D) -> void:
	_jump_pad_exited(body)

func _on_jump_pad_area_entered(area: Area2D) -> void:
	_jump_pad_entered(area.owner)

func _on_jump_pad_area_exited(area: Area2D) -> void:
	_jump_pad_exited(area.owner)

func _jump_pad_entered(node: Node2D):
	if not _entities_to_bounce.has(node):
		_entities_to_bounce[node] = BounceState.AwaitingBounce
	
func _jump_pad_exited(node: Node2D):
	if _entities_to_bounce.get(node) == BounceState.AwaitingBounce:
		# Don't remove entities that are in the process of bouncing
		_entities_to_bounce.erase(node)

func _release_item():
	if absorbed_entity:
		var tree = get_tree()
		if tree:
			absorbed_entity.reparent(get_parent())
			absorbed_entity.get_node("CollisionShape2D").disabled = false
			absorbed_entity.z_as_relative = true
			absorbed_entity.gravity_scale = 1
			absorbed_entity = null
	
func should_bounce(entity):
	var bubble_is_grounded = raycasts.any(func(raycast): return raycast.is_colliding())
	var bubble_touches_floor = downward_raycasts.any(func(raycast): return raycast.is_colliding())
	if not bubble_is_grounded and _needs_grounded_to_bounce: return false

	var _should_bounce = true
	var player = entity as Player
	if player:
		_should_bounce = player.recent_velocity.y > _min_velocity_to_bounce
	else:
		_should_bounce = get_entity_velocity(entity).y > _min_velocity_to_bounce
	
	if is_dynamic:
		if launched:
			# This is to ensure that the player can't fly by just launching downward bubble
			_should_bounce = _should_bounce and (dir != Vector2.DOWN if speed > 0.1 else true)
			#player_ok = player_ok 
		else:
			# Note: We check bubble_is_grounded to allow the player to boing boing boing
			_should_bounce = bubble_is_grounded and player.velocity.y > 0
			if dir == Vector2.DOWN:
				# This is to avoid using walls to trigger a raycast which would trigger a false grounded detecting.
				_should_bounce = _should_bounce and bubble_touches_floor
		
	return _should_bounce

func bounce(entity):
	speed = 0
	
	var bounce_dir = Vector2.UP
	
	var tween = get_tree().create_tween().bind_node(self)
	var initial_velocity = 0
	_bounce(Vector2.ZERO, entity)
	#tween.tween_method(_bounce.bind(entity), Vector2.ZERO, get_entity_velocity(entity), 0.001)#.set_trans(Tween.TRANS_SPRING)
	
	#set_velocity.call(entity, )
	
	var start_position_y = $Sprite2D.position.y
	tween.tween_property($Sprite2D, "position:y", start_position_y + 2, 0.05).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property($Sprite2D, "position:y", 0, 0.05).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(play_bounce_sound)
	tween.set_parallel()
	var scale_modifier = scale.length()
	var minimum_bounce_force = -400
	var jump_force = min(-bounce_force * scale_modifier, minimum_bounce_force) #todo: do * bounce dir
	
	if entity is Player:
		var player = entity as Player
		if player.is_ground_pounding:
			jump_force *= 2
			player.is_ground_pounding = false
	
	tween.set_parallel(false)
	tween.tween_method(_bounce.bind(entity), Vector2.ZERO, Vector2(0, jump_force), 0.01)
	tween.tween_callback(func() :_entities_to_bounce[entity] = BounceState.FinishedBounce).set_delay(0.5)
	tween.set_parallel()
	
	if is_dynamic:
		tween.tween_callback(queue_free)

func _bounce(_velocity, entity):
	if entity is RigidBody2D:
		(entity as RigidBody2D).linear_velocity = _velocity / 1.5
	else:
		(entity as Player).velocity = _velocity

func get_entity_velocity(entity):
	if entity is RigidBody2D:
		return entity.linear_velocity
	else:
		return entity.velocity
	

func _particles() -> void:
	particles.fire()
	particles.owner = null
	particles.reparent(get_parent())

func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			_particles()
			on_disappear.emit()
			_release_item()
		
func play_bounce_sound():
	if is_static:
		$BoingPlayer.play()
	else:
		on_bounce.emit()
		
func play_hit_wall_sound():
	if _can_play_wall_sound:
		_can_play_wall_sound = false
		get_tree().create_timer(0.2).timeout.connect(func():_can_play_wall_sound = false)
		$HitWall.play()

func safety_destroy():
	queue_free()
	
func _process_bouncing(delta: float):
	# Move PreBounce to Bouncing
	for entity in _entities_to_bounce:
		var _state = _entities_to_bounce[entity]
		if _state == BounceState.AwaitingBounce and should_bounce(entity):
			_entities_to_bounce[entity] = BounceState.Bouncing
			bounce(entity)
			
	# Move Bouncing to Bounced
	for entity in _entities_to_bounce.keys():
		var _state = _entities_to_bounce[entity]
		if _state == BounceState.FinishedBounce:
			_entities_to_bounce.erase(entity)

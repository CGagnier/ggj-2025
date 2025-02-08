extends CharacterBody2D

class_name Bubble

signal on_disappear(bubble)

@export var is_static = false
## How high will the player bounce when jumping on it.
@export var bounce_force = 270
@export var can_absorb = true
@export var super_bounce_sound: AudioStream

@export_category("Static Bubble")
@export var sine_intensity: float = 0.0

@export_category("Dynamic Bubbles")
@export var disappear_time: = 1.5
@export var needs_to_be_grounded_to_bounce = false
## How many "bullets" should htis bubble give back
@export var bullet_value = 1
## Force applied to objects that collide with it.
@export var impact_force := 0.0
## How long should we wait before giving a bullet back after pushing an object
@export var impact_give_bullet_back_delay := 0.7

@export var base_speed := 2.0
@export var absorbed_entity: Node2D = null:
	set(val):
		absorbed_entity = val
		if val:
			_absorbed_entity_parent = absorbed_entity.get_parent() if absorbed_entity.get_parent() != self else LevelManager.current_level
		else:
			if _absorbed_entity_sprite:
				_absorbed_entity_sprite.queue_free()
				
			_absorbed_entity_parent = null
			_absorbed_entity_sprite = null
		
@export var destroy_on_bounce: bool = true

## What shooter created this bubble
var shooter = null
var speed := 0.0
var launched = false
var dir = Vector2.RIGHT
var inflate_percent := 0.0
var t := 0.0
var is_dynamic: 
	get: return not is_static

var has_collided = false
var body_started_in_bubble = false
var give_bullet_back_delay := 0.0

var _speed_multiplier = 1
var _min_velocity_to_bounce = 20

var _absorbed_entity_sprite = null
var _absorbed_entity_parent = null
var _is_bouncing = false

var jump_force:
	#todo: Scale this according to the current stage of the bubble
	get:
		return max(bounce_force * scale.length(), 400)

enum BounceState {
	AwaitingBounce,
	Bouncing,
	FinishedBounce	
}

# An entity should only have 1 bounce state 
# Entity -> bounce state, last_detected_dir

class BounceInfo extends RefCounted:
	var bounce_state: BounceState = BounceState.AwaitingBounce
	var last_detected_dir
	
	func _init(_dir: Vector2):
		last_detected_dir = _dir

var _entities_to_info: Dictionary[Node2D, BounceInfo]

# For not detecting collision after absorb
var _completed_absorb = true
var _should_die_after_delay = false

var _can_play_wall_sound = true

var has_pushed = false

@onready var raycasts_map = {
	Vector2.LEFT: [$RaycastLeft, $RaycastLeft2],
	Vector2.UP: [$RaycastUp, $RaycastUp2],
	Vector2.RIGHT: [$RaycastRight, $RaycastRight2],
	Vector2.DOWN: [$RaycastDownLeft, $RaycastDownLeft]
}

var all_raycasts:
	get:
		var _all = []
		for raycast_dir in raycasts_map:
			_all.append_array(raycasts_map[raycast_dir])
		return _all

func collides_in_dir(collide_dir: Vector2):
	return raycasts_map[collide_dir].all(func(rc): return rc.is_colliding())
		

@onready var sine_t := randf() * 10

@onready var particles = $CPUParticles2D
@onready var sprite = $Sprite2D

var collision_pos := Vector2.ZERO

func _ready():
	if absorbed_entity:
		absorb(absorbed_entity)
	
	if is_static:
		set_collision_mask_value(1, 0)
	
	if shooter is not Player:
		# Collide with player if shot by cannon
		set_collision_mask_value(2, true)
	#$HitWall.finished.connect(_on_hit_wall_played)

func _draw() -> void:
	if collision_pos != Vector2.ZERO:
		draw_circle(collision_pos, 10, Color.RED)


func _process(delta: float):
	if is_static:
		sine_t += delta
		global_position.y += sin(sine_t) * sine_intensity / 300
	
	if _absorbed_entity_sprite and _completed_absorb:
		_absorbed_entity_sprite.rotation += delta / 5.0

func _physics_process(delta: float) -> void:
	_process_bouncing(delta)
	if _absorbed_entity_sprite and _completed_absorb:
		_absorbed_entity_sprite.global_position = lerp(_absorbed_entity_sprite.global_position, global_position, delta * 30)
	
	if launched:
		t += delta * 2
		t = min(t, 1.0)
		
		# Activate bounce after a small delay
		speed = base_speed * _speed_multiplier
		
		var collision = move_and_collide(dir *  speed)
		
		# Has collided can be set by other bubbles that collide with it 
		if collision and not has_collided and collision.get_collider() != shooter:
			var collided = collision.get_collider()
			
			collision_pos = collision.get_position()
			
			if collided is Bubble:
				play_hit_wall_sound()
				#var bounce_vector = (self.global_position - collided.global_position).normalized()
				var bounce_vector = (collision_pos - collided.global_position).normalized()
				#dir = dir.bounce(collision.get_normal())
				#dir = dir.normalized()
				dir =_snap_vector(bounce_vector)
			elif collided is Interactable:
				if not absorbed_entity:
					_handle_interactable_collision.call_deferred(collided as Interactable)
			else:
				# re-enable to bounce, this code handles killing the bubble if it contacts something
				#dir = dir.bounce(collision.get_normal())
				
				if is_static: return # Don't kill environment bubbles
				
				if collided is not Player or shooter is not Player and not has_collided:
					var collision_angle = fposmod((collision.get_position() - global_position).angle(), 2*PI)
					var left_margin = fposmod(dir.angle() + deg_to_rad(45), 2*PI)
					var right_margin = fposmod(dir.angle() - deg_to_rad(45), 2*PI)
					
					## This between_angle shit is to ensure that we only stop the bubble on collision if it's hitting in the opossite side of the bubble's direction.
					var between_angles = false
					if left_margin < right_margin:
						between_angles = left_margin <= collision_angle and collision_angle <= right_margin
					else:
						between_angles = collision_angle >= left_margin or collision_angle <= right_margin
					
					if (collision.get_normal() * dir).length() > 0 and not between_angles:
						has_collided = true
						play_hit_wall_sound()
						_speed_multiplier = 0
						_delay_die()
				
func _snap_vector(vector: Vector2) -> Vector2:
	if vector == Vector2.ZERO:
		return Vector2.ZERO  # Avoid snapping a zero vector

	var angle = rad_to_deg(vector.angle())  # Convert the vector's angle to degrees
	const num_possible_angles = 360 / 4
	
	
	var snapped_angle = round(angle / num_possible_angles) * num_possible_angles
	return Vector2.RIGHT.rotated(deg_to_rad(snapped_angle)) 
	
func _delay_die() -> void: 
	if _should_die_after_delay or not _completed_absorb: return #no-op if already scheduled to die
	_should_die_after_delay = true
	var _real_disapear_time = disappear_time if not absorbed_entity else 0.0
	await get_tree().create_timer(_real_disapear_time).timeout
	
	# Possible to be overriden by absorbing an entity
	if _should_die_after_delay:
		queue_free()

func release() -> void:
	launched = true
	
	speed = base_speed
	$SafetyDestroyTimer.timeout.connect(safety_destroy)
	$SafetyDestroyTimer.start()
	
func absorb(interactable: Interactable):
	_completed_absorb = false
	_should_die_after_delay = false
	
	absorbed_entity = interactable
	
	## Duplicate the interactable's sprite and add it to the bubble. 
	var sprite = NodeUtilities.get_child_of_type(absorbed_entity, Sprite2D)
	assert(sprite)
	_absorbed_entity_sprite = sprite.duplicate()
	
	var entity_position = absorbed_entity.global_position
	absorbed_entity.get_parent().remove_child(absorbed_entity)
	LevelManager.current_level.add_child(_absorbed_entity_sprite)
	
	_absorbed_entity_sprite.global_position = entity_position
	#_absorbed_entity_sprite.self_modulate.a = 0.5
	_absorbed_entity_sprite.global_scale = Vector2.ONE	
	# todo: Scale down sprite until it fits in the bubble
	
	_speed_multiplier = 0
	
	await get_tree().create_timer(0.1).timeout
	var tween = get_tree().create_tween()
	
	$Sprite2D.self_modulate.a = 0.7
	
	var target_position_delta = entity_position - global_position
	var target_position = global_position + target_position_delta / 2
	
	var start_scale = $Sprite2D.scale
	
	tween.set_parallel()
	tween.tween_property(self, "global_position", target_position, 0.2).set_delay(0.1).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(_absorbed_entity_sprite, "global_position", target_position, 0.1).set_delay(0.1).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "scale", start_scale * 1.1, 0.1).set_delay(0.1).set_trans(Tween.TRANS_SPRING)
	tween.set_parallel(false)
	
	tween.tween_property($Sprite2D, "scale", start_scale, 0.0).set_trans(Tween.TRANS_SPRING)
	#tween.tween_property($Sprite2D, "scale", start_scale, 0.05)
	
	#tween.tween_property(_absorbed_entity_sprite, "global_position", self.global_position, 0.1)
	#tween.tween_property(self, "_speed_multiplier", 1.5,  0.6).from(0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	var on_finish = func():
		_completed_absorb = true
		if launched:
			_speed_multiplier = 0.8
		
	tween.tween_callback(on_finish).set_delay(0.4)
	

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
	if can_absorb and is_dynamic:
		absorb(interactable)
		dir = Vector2.UP
	else:
		if interactable is RigidBody2D and not has_pushed:
			has_pushed = true
			interactable.apply_impulse(dir * impact_force)
			give_bullet_back_delay = 0.5
			queue_free()

func _on_jump_pad_body_entered(body: Node2D, jump_pad_side: Vector2) -> void:
	_jump_pad_entered(body, jump_pad_side)

func _on_jump_pad_body_exited(body: Node2D, jump_pad_side: Vector2) -> void:
	_jump_pad_exited(body, jump_pad_side)

func _on_jump_pad_area_entered(area: Area2D, jump_pad_side: Vector2) -> void:
	_jump_pad_entered(area.owner, jump_pad_side)

func _on_jump_pad_area_exited(area: Area2D, jump_pad_side: Vector2) -> void:
	_jump_pad_exited(area.owner, jump_pad_side)

func _jump_pad_entered(node: Node2D, bounce_dir: Vector2):
	var bounce_info = _entities_to_info.get_or_add(node, BounceInfo.new(bounce_dir))
	if bounce_info.bounce_state == BounceState.AwaitingBounce:
		bounce_info.last_detected_dir = bounce_dir
	
func _jump_pad_exited(node: Node2D, bounce_dir: Vector2):
	var bounce_info = _entities_to_info.get(node)
	if bounce_info and bounce_info.last_detected_dir == bounce_dir and bounce_info.bounce_state == BounceState.AwaitingBounce:
		# Don't remove entities that are in the process of bouncing
		_entities_to_info.erase(node)

func _release_absorbed_entity():
	if absorbed_entity:
		if is_inside_tree():
			# Make sure to reparent our absorbed entitybsorbed_entity.get_parent() == self:
			absorbed_entity.global_position = global_position
			_absorbed_entity_parent.add_child(absorbed_entity)
			absorbed_entity = null
			_absorbed_entity_parent = null

func should_bounce_in_dir(entity, bounce_dir: Vector2):
	# Bounce dir UP means the player will go up
	
	# Checks that the entity is going towards the bounce area
	var can_bounce_in_dir =  get_entity_velocity(entity).dot(bounce_dir) < -_min_velocity_to_bounce
	
	if is_dynamic:
		if launched:
			# This is to ensure that the player can't fly by just launching downward bubble
			can_bounce_in_dir = can_bounce_in_dir and (dir != -bounce_dir if speed > 0.1 else true)
		else:
			# Note: We check bubble_is_grounded to allow the player to boing on wall
			can_bounce_in_dir = can_bounce_in_dir and collides_in_dir(-bounce_dir)
	
	return can_bounce_in_dir

func bounce(entity, bounce_dir):
	_is_bouncing = true
	speed = 0
	
	if absorbed_entity:
		entity.add_collision_exception_with(absorbed_entity)
		var _reenable_collision_with_absorbed = func():
			if absorbed_entity:
				entity.remove_collision_exception_with(absorbed_entity)
				
		get_tree().create_timer(0.5).timeout.connect(_reenable_collision_with_absorbed)
		
	var tween = get_tree().create_tween().bind_node(self)
	
	var component = "x" if bounce_dir == Vector2.LEFT or bounce_dir == Vector2.RIGHT else "y"
	var other_component = "y" if component == "x" else "x"
	
	_set_entity_velocity(Vector2(0,0), entity)
	
	var bounce_sign = sign(bounce_dir[component])
	var final_bubble_position = -bounce_dir * 5

	# Handle bubble movement
	tween.tween_property($Sprite2D, "position", final_bubble_position, 0.05).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property($Sprite2D, "position", Vector2.ZERO, 0.05).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(play_bounce_sound.bind($BoingPlayer))
	
	var dir_bounce_force = jump_force * bounce_dir

	tween.set_parallel()
		
	tween.tween_callback(_set_entity_velocity.bind(dir_bounce_force, entity))
	tween.tween_callback(func() :_entities_to_info[entity].bounce_state = BounceState.FinishedBounce).set_delay(0.5)
	
	var is_super_jump = InputBuffer.is_action_press_buffered("jump", 150) and entity is Player
	
	if is_super_jump:
		tween.tween_callback(_set_entity_velocity.bind(dir_bounce_force * 1.2, entity))
		tween.tween_callback(play_bounce_sound.bind($SuperBoingPlayer))
	
	if destroy_on_bounce:
		tween.tween_callback(queue_free)
	

func _set_entity_velocity(_velocity, entity):
	if entity is RigidBody2D:
		(entity as RigidBody2D).linear_velocity = _velocity / 1.5
	else:
		(entity as Player).velocity = _velocity

func get_entity_velocity(entity, recent = true):
	if entity is Player and recent:
		return entity.recent_velocity	
	elif entity is RigidBody2D:
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
			on_disappear.emit(self)
			_release_absorbed_entity()
		
func play_bounce_sound(audio_player: AudioStreamPlayer2D):
	if is_dynamic:
		audio_player.pitch_scale = 1.2 - (inflate_percent*0.2)

	if destroy_on_bounce:
		var boing_player = audio_player
		if boing_player:
			boing_player.reparent(LevelManager.current_level)
			boing_player.finished.connect(boing_player.queue_free)
			boing_player.play()
	else:
		audio_player.play()
		
func play_hit_wall_sound():
	if _can_play_wall_sound:
		_can_play_wall_sound = false
		get_tree().create_timer(0.2).timeout.connect(func():_can_play_wall_sound = false)
		$HitWall.play()

### Destroy a bubble if it was left alive for too long
### Note, we're not destroying bubbles with shit inside of it.
func safety_destroy():
	if not absorbed_entity and not _is_bouncing:
		queue_free()
	
func _process_bouncing(_delta: float):
	# Move PreBounce to Bouncing
	for entity in _entities_to_info:
		var info = _entities_to_info[entity]
		if info.bounce_state == BounceState.AwaitingBounce and should_bounce_in_dir(entity, info.last_detected_dir):
			info.bounce_state = BounceState.Bouncing
			bounce(entity, info.last_detected_dir)
					
			# Move Bouncing to Bounced
	for entity in _entities_to_info.keys():
		var info = _entities_to_info[entity]
		if info.bounce_state == BounceState.FinishedBounce:
			_entities_to_info.erase(entity)

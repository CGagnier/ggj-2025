extends CharacterBody2D

class_name Bubble

signal on_disappear
signal on_bounce

@export var is_static = false
@export var bounce_force = 250

@export_category("Static Bubble")
@export var sine_intensity: float = 0.0

@export_category("Dynamic Bubbles")
@export var start_speed := 5.0
@export var final_speed := 4.0
@export var disappear_time: = 1.5
@export var can_bounce_on_wall = false

var speed = 2
var launched = false
var dir = Vector2.RIGHT
var inflate_percent := 0.0
var player: Player = null
var t := 0.0

var collided = false
var body_started_in_bubble = false
var absorbed_entity = null
var _speed_multiplier = 1
var _player_in_bubble = false
var _player_velocity_to_bounce = 50

# For not detecting collision after absorb
var _dont_check_collision_timer := 0.5
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
	if should_bounce_player():
		bounce_player()
			
	if launched:
		t += delta * 2
		t = min(t, 1.0)
		
		# Activate bounce after a small delay
		speed = lerpf(start_speed, final_speed, t) * _speed_multiplier
		
		var collision = move_and_collide(dir *  speed)
		
		if collision and not collided:
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
	await get_tree().create_timer(disappear_time).timeout
	
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
	other_bubble.collided = true # prevent other bubble from detecting same collision
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
	if body is Player:
		player = body as Player
		_player_in_bubble = true

func _on_jump_pad_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_bubble = false
	
	if not launched:
		body_started_in_bubble = false

func _release_item():
	if absorbed_entity:
		var tree = get_tree()
		if tree:
			absorbed_entity.reparent(get_parent())
			absorbed_entity.get_node("CollisionShape2D").disabled = false
			absorbed_entity.z_as_relative = true
			absorbed_entity.gravity_scale = 1
			absorbed_entity = null
	
func should_bounce_player():
	if player and player.recent_velocity.y > _player_velocity_to_bounce and _player_in_bubble:
		if is_static:
			return true # Static bubbles always bounce
		
		if can_bounce_on_wall:
			if raycast_left.is_colliding() or raycast_right.is_colliding() or raycast_left2.is_colliding() or raycast_right2.is_colliding():
				return true
		
		return (raycast_down_left.is_colliding() and raycast_down_right.is_colliding())
	
	return false

func bounce_player():
	speed = 0
	var tween = get_tree().create_tween()
	player.velocity.y = 0
	
	var base_scale = scale
	#tween.tween_property(self, "scale", scale * Vector2(1, 0.9), 0.05).set_trans(Tween.TRANS_BOUNCE)
	#tween.tween_property(self, "scale", base_scale, d0.05).set_trans(Tween.TRANS_CUBIC)
	var start_position_y = $Sprite2D.position.y
	tween.tween_property($Sprite2D, "position:y", start_position_y + 2, 0.05).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property($Sprite2D, "position:y", 0, 0.05).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(play_bounce_sound)
	tween.set_parallel()
	var scale_modifier = scale.length()
	var jump_force = -bounce_force * scale_modifier #todo: do * bounce dir
	tween.tween_property(player, "velocity:y", jump_force, 0.01).set_trans(Tween.TRANS_BOUNCE)
	
	if not is_static:
		tween.tween_callback(queue_free)

func _particles() -> void:
	particles.fire()
	particles.reparent(get_parent())

func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			_particles()
			on_disappear.emit()
			_release_item()

func _on_jump_pad_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		player = area.owner
		_player_in_bubble = true

func _on_jump_pad_area_exited(area: Area2D) -> void:
	if area.owner is Player:
		_player_in_bubble = false
		
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

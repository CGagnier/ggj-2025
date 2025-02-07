@tool

extends Interactable

@export var item_scene: PackedScene
@export var broken_crate: PackedScene
@export var distance_to_break: float

var can_break = true
var broken = false

## Whether this will break on the next impact downwards.
var _will_break_on_impact = false

var last_velocities = []

var falling_initial_pos = null
var fallen_distance := 0.0

const NUM_VELOCITIES = 1

@onready var initial_scale = scale
@onready var box_size = $Sprite2D.get_rect().size

## Debug info
var _contact_position = null
var _last_falling_initial_pos = null

var started_in_air = false

func _ready():
	$AudioStreamPlayer2D.finished.connect(queue_free)
	contact_monitor = false
	get_tree().create_timer(2).timeout.connect(func(): contact_monitor = true)
	if not $GroundRaycast.is_colliding():
		started_in_air = true
	


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw();

func _draw() -> void:
	if not Settings.debug or not box_size: return
	
	var box_offset = Vector2(box_size.x / 2.0, 0)
	var raycast_length = $GroundRaycast.target_position.y
	var real_distance_to_break = distance_to_break - raycast_length
	if started_in_air:
		draw_dashed_line(Vector2.ZERO, Vector2(0, real_distance_to_break), Color.GREEN, 2.0)
		var line_end =  Vector2(0, real_distance_to_break)
		var line_width = Vector2(10, 0)
		draw_line(line_end - line_width, line_end + line_width, Color.GREEN, 2.0)
	
	if _last_falling_initial_pos:
		var draw_color = Color.WHITE
		draw_color.a = 0.4
		draw_texture($Sprite2D.texture, to_local(_last_falling_initial_pos) - box_offset, draw_color)
		var initial = to_local(_last_falling_initial_pos)
		# todo: If not grounded, draw this arrow
		var dotted_end = initial + Vector2(0, real_distance_to_break)
		draw_dashed_line(initial, dotted_end, Color.GREEN, 2.0)
		var line_width = Vector2(10, 0)
		draw_line(dotted_end - line_width, dotted_end + line_width, Color.GREEN, 2.0)
	
	if _contact_position:
		var draw_color = Color.WHITE
		draw_color.a = 0.4
		draw_texture($Sprite2D.texture, to_local(_contact_position) - box_offset, draw_color)

func _physics_process(_delta: float) -> void:
	if Settings.debug:
		queue_redraw()
		
	_detect_ground_collision()
		
	last_velocities.push_back(linear_velocity.y)
	if last_velocities.size() > NUM_VELOCITIES:
		last_velocities.pop_front()
	
	var mean_velocities = last_velocities.reduce(sum, 0) / NUM_VELOCITIES
	if falling_initial_pos == null and mean_velocities > 1:
		falling_initial_pos = global_position - $GroundRaycast.target_position
	elif mean_velocities < 0:
		falling_initial_pos = null
		fallen_distance = 0.0
	
	if falling_initial_pos:
		_last_falling_initial_pos = falling_initial_pos if not _last_falling_initial_pos else _last_falling_initial_pos
		fallen_distance = global_position.y - falling_initial_pos.y
		if fallen_distance >= distance_to_break - $GroundRaycast.target_position.y:
			_will_break_on_impact = true

func sum(accum, number):
	return accum + number

func _on_body_entered(body: Node) -> void:
	if not broken:
		$ContactStreamPlayer.play()

func _spawn_item():	
	if item_scene:
		var new_item = item_scene.instantiate()
		LevelManager.current_level.add_child.call_deferred(new_item)
		new_item.global_position = $ItemSpawnPoint.global_position
		new_item.scale.y = 0
		new_item.scale.x *= sign(initial_scale.x)
		get_tree().create_tween().tween_property(new_item, "scale:y", 1, 0.3).set_ease(Tween.EASE_OUT)
	
func _detect_ground_collision():
	if $GroundRaycast.is_colliding() and not broken:
		
		if not _contact_position: _contact_position = global_position
		if can_break and _will_break_on_impact:
			broken = true
			set_collision_layer_value(5, 0)
			set_collision_mask_value(5, 0)
			
			_spawn_broken_crate()
			get_tree().create_timer(0.2).timeout.connect(_spawn_item)
		else:
			falling_initial_pos = null
			fallen_distance = 0.0

func _spawn_broken_crate():
	if broken_crate:
		var instance: Node2D = broken_crate.instantiate()
		LevelManager.current_level.add_child.call_deferred(instance)
		instance.global_position = global_position
		instance.z_index = 2
		$AudioStreamPlayer2D.play()
		visible = false

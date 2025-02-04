extends Interactable

@export var item_scene: PackedScene
@export var break_velocity := 400
@export var broken_crate: PackedScene

@export var spawn_parent = null


var can_break = true
var broken = false

var last_velocities = []

@onready var initial_scale = scale

func _ready():
	$AudioStreamPlayer2D.finished.connect(queue_free)
	contact_monitor = false
	get_tree().create_timer(2).timeout.connect(func(): contact_monitor = true)
	if not spawn_parent:
		spawn_parent = get_parent()

func _physics_process(_delta: float) -> void:
	last_velocities.push_back(linear_velocity.y)
	if last_velocities.size() > 5:
		last_velocities.pop_front()

func sum(accum, number):
	return accum + number

func _on_body_entered(body: Node) -> void:
	if not broken:
		$ContactStreamPlayer.play()
		
	var _can_break = body is Interactable
	
	var angle = rad_to_deg(get_angle_to(body.global_position))
	#print(angle)
	
	if not broken and (_can_break or body is TileMapLayer or body is StaticBody2D):
		var mean_velocities = last_velocities.reduce(sum, 0) / 5
		if mean_velocities >= break_velocity and can_break:
			broken = true
			set_collision_layer_value(5, 0)
			set_collision_mask_value(5, 0)
			#$CollisionShape2D.set_deferred("disabled", true)
			
			if broken_crate:
				var instance: Node2D = broken_crate.instantiate()
				spawn_parent.add_child.call_deferred(instance)
				instance.global_position = global_position
				instance.z_index = 2
				$AudioStreamPlayer2D.play()
				visible = false
			
			get_tree().create_timer(0.2).timeout.connect(_spawn_item)
			

func _spawn_item():	
	if item_scene:
		var new_item = item_scene.instantiate()
		spawn_parent.add_child.call_deferred(new_item)
		new_item.global_position = $ItemSpawnPoint.global_position
		new_item.scale.y = 0
		new_item.scale.x *= sign(initial_scale.x)
		get_tree().create_tween().tween_property(new_item, "scale:y", 1, 0.3).set_ease(Tween.EASE_OUT)
	

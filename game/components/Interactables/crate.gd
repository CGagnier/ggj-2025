extends Interactable

@export var item_scene: PackedScene
@export var break_velocity := 400
@export var broken_crate: PackedScene

var last_velocity:Vector2

var can_break = false

var last_velocities = []

func _ready():
	get_tree().create_timer(2).timeout.connect(func(): can_break = true)

func _physics_process(delta: float) -> void:
	last_velocities.push_back(linear_velocity.y)
	if last_velocities.size() > 5:
		last_velocities.pop_front()

func sum(accum, number):
	return accum + number

func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer:
		var mean_velocities = last_velocities.reduce(sum, 0) / 5
		
		if mean_velocities >= break_velocity and can_break:
			queue_free()
			#var instance = broken_crate.instantiate()
			#get_tree().root.add_child.call_deferred(instance)
			
			if item_scene:
				var new_item = item_scene.instantiate()
				get_tree().root.add_child.call_deferred(new_item)
				new_item.global_position = global_position

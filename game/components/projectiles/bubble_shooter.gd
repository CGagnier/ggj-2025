extends Node2D

@export var ProjectileScene: PackedScene
@export var start_scale = Vector2(0.5, 0.5)
@export var max_scale: Vector2 = Vector2(2,2)
@export var growth_rate = 1

var current_projectile: Node2D = null

var shoot_dirs = ["shoot_left", "shoot_up", "shoot_right", "shoot_down"]

var input_to_dir: Dictionary[String, Vector2] = {
	"shoot_left": Vector2.LEFT,
	"shoot_up": Vector2.UP,
	"shoot_right": Vector2.RIGHT,
	"shoot_down": Vector2.DOWN
}

var current_shoot_dir = Vector2.RIGHT

func _input(event: InputEvent) -> void:
	pass

func _physics_process(delta: float) -> void:
	for shoot_dir in shoot_dirs:
		if Input.is_action_just_pressed(shoot_dir) and not current_projectile:
			_create_bubble()

	for shoot_dir in shoot_dirs:
		if Input.is_action_pressed(shoot_dir):
			if current_projectile and current_projectile.scale < max_scale: 
				current_projectile.global_scale *= (1 + growth_rate * delta)
				current_shoot_dir = input_to_dir.get(shoot_dir)
				break
	
	for shoot_dir in shoot_dirs:
		if input_to_dir.get(shoot_dir) == current_shoot_dir and Input.is_action_just_released(shoot_dir):
			_let_go()


func _create_bubble() -> void:
	var _new_bubble = ProjectileScene.instantiate()
	_new_bubble.scale = start_scale
	current_projectile = _new_bubble
	add_child(current_projectile)


func _let_go() -> void:
	if current_projectile:
		#todo: use current dir
		current_projectile.dir = current_shoot_dir
		current_projectile.reparent(get_parent().get_parent())
		current_projectile.release()
		current_projectile = null

extends CharacterBody2D


var SPEED = 100.0

var max_scale = Vector2(4,4)

@export var projectile: PackedScene
var current_projectile: Bubble
var current_scale = Vector2(1,1)

func _create_bubble() -> void:
	var _new_bubble = projectile.instantiate()
	current_projectile = _new_bubble
	add_child(current_projectile)

func _let_go() -> void:
	if current_projectile:
		current_projectile.reparent(get_parent())
		current_projectile.release(current_projectile.global_scale)

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("blow"):
		print("start blowing")
		_create_bubble()

	
	if Input.is_action_pressed("blow"):
		if current_projectile and current_projectile.global_scale < max_scale: 
			current_projectile.global_scale *= 1.05
			current_scale *= 1.05
		
	if Input.is_action_just_released("blow"):
		print("and go")
		_let_go()

	if Input.is_action_just_pressed("click"):
		pass

#	move_and_slide()
	

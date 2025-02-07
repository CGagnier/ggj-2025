extends Node2D

var snap_distance = 30

var corrected_position:
	get:
		return $RigidBody2D.global_position

var target_position:
	get:
		return $TargetPosition.global_position
	set(val):
		$TargetPosition.global_position = val

func _physics_process(delta: float) -> void:
	var target_loc = $TargetPosition.position
	var movement = target_loc - $RigidBody2D.position
	
	var start_distance = target_loc - $RigidBody2D.position
	if start_distance.length() > snap_distance:
		$RigidBody2D.position = $RigidBody2D.position.move_toward(target_loc, start_distance.length() - snap_distance)
	
	movement = lerp($RigidBody2D.position, target_loc, delta * 10)
	$RigidBody2D.move_and_collide(movement - $RigidBody2D.position)

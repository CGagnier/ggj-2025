@tool 
extends Node2D

var object_path: NodePath

@export var _object: Node2D

@export var object: NodePath:
	set(val):
		# todo: Construct relative node path to remote node? 
		object_path = val
		#$platform_moving/RemoteTransform2D.remote_path = val
	get:
		return object_path
		#return $platform_moving/RemoteTransform2D.remote_path
		

@export var length: float =  100:
	set(val):
		$platform_waypoint2.position.x = val
		queue_redraw()
	get():
		return $platform_waypoint2.position.x

func _draw() -> void:
	draw_dashed_line($platform_waypoint.position, $platform_waypoint2.position, Color.FLORAL_WHITE, 2.0)
	
func _ready():
	if _object:
		_object.position = Vector2.ZERO
		_object.reparent.call_deferred($platform_moving, false)
		
	#$platform_moving/RemoteTransform2D.remote_path = object_path
	queue_redraw()

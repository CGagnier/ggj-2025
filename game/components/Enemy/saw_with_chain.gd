extends Node2D

@onready var line = $Line2D
@onready var line_anchor = $root
@onready var hook = $saw

func _physics_process(delta):
		line.points[0] = line_anchor.position
		line.points[1] = hook.position

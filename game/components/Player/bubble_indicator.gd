extends AnimatedSprite2D

class_name BubbleIndicator

@onready var bubble_indicator: AnimatedSprite2D = $"."

var num_gums = 3:
	set(val):
		var target_frame = min(3, val)
		bubble_indicator.frame = 3 - target_frame
		
func _ready():
	num_gums = 3

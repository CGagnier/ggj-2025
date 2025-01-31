extends Node2D

@export var bubble_speed := 4.0
@export var max_bubble_scale := 1.0
@export var shoot_delay := 0.3

func _ready() -> void:
	$StaticBubbleShooter.bubble_created.connect(_on_bubble_created)
	$StaticBubbleShooter.bubble_shot.connect(_on_bubble_shot)
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)
	
	$StaticBubbleShooter.projectile_speed = bubble_speed
	$StaticBubbleShooter.shoot_delay = shoot_delay
	$StaticBubbleShooter.shooter_ref = self
	$StaticBubbleShooter.max_scale = Vector2(max_bubble_scale, max_bubble_scale)
	
func _on_bubble_created():
	pass
	
func _on_bubble_shot():
	$AnimatedSprite2D.play("shoot")

func _on_anim_finished():
	if $AnimatedSprite2D.animation == "shoot":
		$AnimatedSprite2D.play("windup")

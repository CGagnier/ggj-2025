extends StaticBody2D

# List of Projectiles
@export var ProjectileStats: Array[BallStat]
@export var projectile_scene: PackedScene

# Rate of Fire  
@export var RateOfFire = 3.0

# Child nodes
@onready var Cooldown: Timer = $CooldownTimer
@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	Fire_Projectile(false)

func _process(delta: float) -> void:
	pass

func Fire_Projectile(DoOnce = true) -> void:
	AnimatedSprite.play("Shoot")
	if (!DoOnce):
		Cooldown.start(RateOfFire)
	
func SpawnProjectile() -> void:	
	var ProjectileStat = ProjectileStats.pick_random()
	if (ProjectileStat != null):
		var _proj:Ball = projectile_scene.instantiate()
		_proj.direction = Vector2(-1,0)*scale.x
		_proj.stat = ProjectileStat
		add_child(_proj)

func Stop_Firing() -> void:
	Cooldown.stop()

func _on_timer_timeout() -> void:
	Fire_Projectile(false)

func _on_animated_sprite_2d_frame_changed() -> void:
	if(AnimatedSprite.animation == "Shoot"):
		if(AnimatedSprite.frame == 1):
			SpawnProjectile()

func _on_animated_sprite_2d_animation_finished() -> void:
	if(AnimatedSprite.animation == "Shoot"):
		if(AnimatedSprite.frame == 3):	
			AnimatedSprite.play("Idle")

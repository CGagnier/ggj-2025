extends Sprite2D

var sine_t := 0.0

func _ready() -> void:
	sine_t = randf()

func _process(delta: float) -> void:
	var sine_intensity = 0.02
	sine_t += delta
	global_position.y += sin(sine_t * 2) * sine_intensity

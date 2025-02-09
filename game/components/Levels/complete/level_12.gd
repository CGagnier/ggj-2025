extends Level

func _ready() -> void:
	super._ready()
	$BreakablePillar.broke.connect($Canon.queue_free)

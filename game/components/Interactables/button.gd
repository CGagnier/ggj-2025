extends StaticBody2D

signal pushed

## Time between button push and signal emitted.
@export var signal_delay = 0.7
@export var push_animation_length = 0.1
@export var free_player_delay = 0.4

var _pushed = false
var _pushing_entity = null
var _pushing_entity_initial_position

func _ready() -> void:
	$PushArea.body_entered.connect(_button_pushed)
	
func _physics_process(delta: float) -> void:
	if _pushing_entity:
		_pushing_entity.global_position.x = _pushing_entity_initial_position.x
	
	if not pushed:
		var bodies = $PushArea.get_overlapping_bodies()
	
func _button_pushed(body):
	if not _pushed:
		# Lock entity to button while pushing
		_pushing_entity = body
		_pushing_entity_initial_position = _pushing_entity.global_position
		get_tree().create_timer(push_animation_length).timeout.connect(_handle_push_deferred)
	
	#todo sound


func _handle_push_deferred():
	$AnimatedSprite2D.animation = "pushed"
	$PushArea.monitoring = false
	$InitialCollisionShape.disabled = true
	$PushedCollisionShape.disabled = false
	
	_pushed = true
	_pushing_entity = null
	get_tree().create_timer(free_player_delay).timeout.connect(func():_pushing_entity=null)
	get_tree().create_timer(signal_delay).timeout.connect(pushed.emit)

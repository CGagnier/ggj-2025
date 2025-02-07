extends Node

class_name GameSettings

enum ControlScheme {
	WasdAndSpaceToShoot,
	ArrowKeysToShoot
}

@export var control_scheme: ControlScheme = ControlScheme.WasdAndSpaceToShoot
@export var play_music: bool = false
## Whether to show debug stuff (ie. crate distance to blow)
@export var debug = false

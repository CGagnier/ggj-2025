extends Node

class_name GameSettings

enum ControlScheme {
	WasdAndSpaceToShoot,
	ArrowKeysToShoot
}

@export var control_scheme: ControlScheme = ControlScheme.WasdAndSpaceToShoot

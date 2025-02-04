extends Resource

class_name InflateState

@export var max_scale := 1.0
## How long the bubble stays in this state before moving to the next one
@export var state_time := 0.33
@export var speed := 1.0
## Whether this bubble can absorb objects to make them levitate.
@export var can_absorb = true
## Force applied by this bubble when it collides with an object.
@export var impact_force := 10.0
## pitch scale of the inflate sound being played
@export var audio_pitch_scale := 1.0

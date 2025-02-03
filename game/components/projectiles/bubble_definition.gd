extends Resource

class_name BubbleDefinition

## The stages when you hold the shoot button
@export var inflate_states: Array[InflateState]
## How long you can hold the bubble before it pops without shooting
@export var time_to_pop: float = 1.0
@export var bubble_type = "Normal"
#@export var indicator: BubbleIndicator

# TODO add pause time between inflates

var num_states:
	get:
		return inflate_states.size()

func get_state(index: int):
	return inflate_states[index]

# export indicator 

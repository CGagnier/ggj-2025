extends Node2D

@onready var initial_shouldnt_break_count = get_tree().get_nodes_in_group("ShouldntBreak").size()

func _ready():
	## Initialize current level in level_manager
	if not LevelManager.current_level and not LevelManager.launched_from_main:
		LevelManager.current_level = self
	
	# Pop the bubble to free the item
	get_tree().create_timer(1).timeout.connect($Bubble.queue_free)
	get_tree().create_timer(3).timeout.connect(verify_test)

func verify_test():
	var should_break = get_tree().get_nodes_in_group("ShouldBreak")
	var shouldnt_break = get_tree().get_nodes_in_group("ShouldntBreak")
	
	var test_pass = true
	test_pass = should_break.size() == 0
	test_pass = test_pass and initial_shouldnt_break_count == shouldnt_break.size()
	
	if test_pass:
		$TestResultLabel.text = "Success"
	else:
		$TestResultLabel.text = "Failure"
	
	$TestResultLabel.visible = true

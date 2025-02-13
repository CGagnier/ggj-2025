# Credit: balintbarna (https://github.com/godotengine/godot-proposals/issues/3661#issuecomment-1003397595)

class_name NodeUtilities

# Note: passing a value for the type parameter causes a crash
static func get_child_of_type(node: Node, child_type):
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if is_instance_of(child, child_type):
			return child


# Note: passing a value for the type parameter causes a crash
static func get_children_of_type(node: Node, child_type):
	var list = []
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if is_instance_of(child, child_type):
			list.append(child)
	return list

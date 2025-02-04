@tool
extends EditorPlugin

var is_debug: = false
# List of all ScriptCreateDialog instances
var script_create_dialogs: Array = []

func _enter_tree():
	if is_debug: print("Plugin enabled: Entering tree")

	# Search and collect all instances of ScriptCreateDialog
	var editor_interface = get_editor_interface()
	var base_control = editor_interface.get_base_control()

	# Clear any previous references
	script_create_dialogs.clear()

	# Find and store all ScriptCreateDialog instances
	_find_script_create_dialogs_recursive(base_control)

	# Connect the signal for each ScriptCreateDialog instance
	for dialog in script_create_dialogs:
		if is_debug: print("Found ScriptCreateDialog instance: ", dialog)
		dialog.script_created.connect(_on_script_created)
		if is_debug: print("Connected to script_created signal of ", dialog)

func _exit_tree():
	if is_debug: print("Plugin disabled: Exiting tree")
	# Disconnect the signal from all ScriptCreateDialog instances
	for dialog in script_create_dialogs:
		if is_debug: print("Disconnecting signal from ScriptCreateDialog: ", dialog)
		dialog.script_created.disconnect(_on_script_created)
		if is_debug: print("Disconnected from signal of ", dialog)

func _find_script_create_dialogs_recursive(node):
	# If the node is a ScriptCreateDialog, add it to the list
	if is_instance_of(node, ScriptCreateDialog):
		if is_debug: print("ScriptCreateDialog located: ", node)
		script_create_dialogs.append(node)
	# Recurse through all children of the node
	for child in node.get_children():
		_find_script_create_dialogs_recursive(child)

func _on_script_created(script: Script):
	if is_debug: print("in _on_script_created function")
	if script:
		if is_debug: print("Script created: ", script.resource_path)
		if (script.resource_path.ends_with(".gd") ||
			script.resource_path.ends_with(".cs")
		):
			if is_debug: print("Opening .gd script in the editor")
			# Automatically open the created script in the editor
			get_editor_interface().edit_resource(script)
	else:
		if is_debug: print("Script creation failed or script is null")

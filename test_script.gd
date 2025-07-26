extends Control

func _ready():
	print("Test script: _ready() called")
	print("Test script: Scene tree is valid: ", is_inside_tree())
	print("Test script: Node name: ", name)
	print("Test script: Parent: ", get_parent().name if get_parent() else "None")
	print("Test script: Test completed successfully")

func _process(delta):
	# Keep the scene alive
	pass 
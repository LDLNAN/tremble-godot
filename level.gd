extends Node3D

const SPAWN_RANDOM := 5.0

func _ready():
	print("=== LEVEL _READY() CALLED ===")
	
	# Always manually instantiate the pause menu
	print("=== ATTEMPTING TO MANUALLY INSTANTIATE PAUSE MENU ===")
	
	# Try to load the pause menu scene
	var pause_menu_scene = load("res://scenes/ui/pause_menu.tscn")
	if pause_menu_scene:
		print("=== PAUSE MENU SCENE LOADED SUCCESSFULLY ===")
		var pause_menu = pause_menu_scene.instantiate()
		print("=== PAUSE MENU INSTANTIATED ===")
		pause_menu.name = "PauseMenu"
		pause_menu.visible = false
		add_child(pause_menu)
		print("=== PAUSE MENU ADDED TO SCENE TREE ===")
		# Check if the script is attached
		if pause_menu.get_script():
			print("=== PAUSE MENU SCRIPT ATTACHED: ", pause_menu.get_script().get_global_name(), " ===")
		else:
			print("=== PAUSE MENU SCRIPT NOT ATTACHED ===")
		
		# Register with input handler
		if InputHandler:
			print("=== INPUT HANDLER FOUND, REGISTERING ===")
			InputHandler.set_in_game(self)
			InputHandler.set_pause_menu(pause_menu)
			print("=== REGISTERED WITH INPUT HANDLER ===")
		else:
			print("=== ERROR: INPUT HANDLER NOT FOUND! ===")
	else:
		print("=== FAILED TO LOAD PAUSE MENU SCENE ===")
		# Create a simple test pause menu as fallback
		print("=== CREATING SIMPLE TEST PAUSE MENU ===")
		var test_pause_menu = Control.new()
		test_pause_menu.name = "PauseMenu"
		test_pause_menu.visible = false
		test_pause_menu.set_script(load("res://scripts/ui/pause_menu.gd"))
		add_child(test_pause_menu)
		print("=== SIMPLE TEST PAUSE MENU CREATED ===")
		
		# Register with input handler
		if InputHandler:
			InputHandler.set_in_game(self)
			InputHandler.set_pause_menu(test_pause_menu)
			print("=== REGISTERED WITH INPUT HANDLER ===")
	
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)


func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


func add_player(id: int):
	var character = preload("res://player.tscn").instantiate()
	# Set player id.
	character.player = id
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	character.name = str(id)
	$Players.add_child(character, true)
	
	# Register the player with the input handler if it's the local player
	if id == multiplayer.get_unique_id():
		if InputHandler:
			InputHandler.set_in_game(character)
			print("=== REGISTERED PLAYER WITH INPUT HANDLER ===")


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()

# Input handling is now managed by the InputHandler singleton
# The level script no longer needs to handle input directly

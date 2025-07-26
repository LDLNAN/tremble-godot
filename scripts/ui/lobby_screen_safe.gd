extends Control

# Lobby Screen - Handles multiplayer hosting and joining

# UI References
var host_button: Button
var join_button: Button
var server_address_input: LineEdit
var back_button: Button
var status_label: Label

func _ready():
	print("LobbyScreen Safe: _ready() called")
	
	# Wait one frame to ensure all nodes are properly instantiated
	await get_tree().process_frame
	
	# Find UI references safely
	find_ui_references()
	
	# Set up button connections
	print("LobbyScreen Safe: Setting up connections...")
	setup_connections()
	
	# Set default server address
	if server_address_input:
		server_address_input.text = "127.0.0.1"
		print("LobbyScreen Safe: Default server address set")
	
	# Update status
	update_status("Ready to host or join")
	
	print("LobbyScreen Safe: _ready() completed")

func find_ui_references():
	# Find UI elements
	host_button = get_node_or_null("VBoxContainer/HostButton")
	join_button = get_node_or_null("VBoxContainer/JoinButton")
	server_address_input = get_node_or_null("VBoxContainer/ServerAddressInput")
	back_button = get_node_or_null("VBoxContainer/BackButton")
	status_label = get_node_or_null("StatusLabel")
	
	print("LobbyScreen Safe: UI references found:")
	print("  - host_button: ", host_button != null)
	print("  - join_button: ", join_button != null)
	print("  - server_address_input: ", server_address_input != null)
	print("  - back_button: ", back_button != null)
	print("  - status_label: ", status_label != null)

func setup_connections():
	# Connect buttons
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
		print("LobbyScreen Safe: Host button connected")
	
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
		print("LobbyScreen Safe: Join button connected")
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("LobbyScreen Safe: Back button connected")

func update_status(message: String):
	if status_label:
		status_label.text = message
		print("LobbyScreen Safe: Status updated: ", message)

func _on_host_pressed():
	print("Host button pressed")
	update_status("Starting server...")
	
	# Transition to multiplayer scene for hosting
	start_multiplayer_game(true)

func _on_join_pressed():
	print("Join button pressed")
	
	# Get server address
	var server_address = ""
	if server_address_input:
		server_address = server_address_input.text.strip_edges()
	
	if server_address == "":
		OS.alert("Please enter a server address")
		return
	
	update_status("Connecting to " + server_address + "...")
	
	# Transition to multiplayer scene for joining
	start_multiplayer_game(false, server_address)

func _on_back_pressed():
	print("Back button pressed")
	# Return to main menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_main_menu"):
		game_root.show_main_menu()
	else:
		print("ERROR: GameRoot show_main_menu method not found")

func start_multiplayer_game(is_hosting: bool, server_address: String = ""):
	print("Starting multiplayer game...")
	update_status("Loading multiplayer scene...")
	
	# Hide the UI
	visible = false
	
	# Load the multiplayer scene
	var multiplayer_scene = load("res://multiplayer.tscn")
	if multiplayer_scene:
		# Add the multiplayer scene to the current scene
		var multiplayer_instance = multiplayer_scene.instantiate()
		get_parent().add_child(multiplayer_instance)
		
		# Get the multiplayer script instance
		var multiplayer_script = multiplayer_instance.get_node_or_null(".")
		if multiplayer_script and multiplayer_script.has_method("setup_from_lobby"):
			# Pass the hosting/joining info to the multiplayer scene
			multiplayer_script.setup_from_lobby(is_hosting, server_address)
		else:
			print("WARNING: Multiplayer scene doesn't have setup_from_lobby method")
		
		print("LobbyScreen Safe: Multiplayer scene loaded")
	else:
		print("ERROR: Failed to load multiplayer scene")
		update_status("Failed to load game")
		visible = true 
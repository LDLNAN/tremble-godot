extends Control
class_name LobbyScreen

# Lobby Screen - Multiplayer game setup

# UI References
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var server_address_input: LineEdit = $VBoxContainer/ServerAddressInput
@onready var player_list: VBoxContainer = $PlayerList
@onready var status_label: Label = $StatusLabel

# Network state
var is_hosting: bool = false
var is_connected: bool = false

func _ready():
	# Set up button connections
	setup_connections()
	
	# Set default server address
	if server_address_input:
		server_address_input.text = "127.0.0.1"
	
	# Update status
	update_status("Ready to host or join")
	
	# Grab focus
	host_button.grab_focus()

func setup_connections():
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_host_pressed():
	print("Host button pressed")
	is_hosting = true
	update_status("Starting server...")
	
	# Use the existing multiplayer system
	var multiplayer_node = get_node_or_null("/root/Multiplayer")
	if multiplayer_node and multiplayer_node.has_method("_on_host_pressed"):
		multiplayer_node._on_host_pressed()
		# Transition to game
		start_game()
	else:
		# Fallback: create a simple multiplayer setup
		create_simple_multiplayer()
		start_game()

func _on_join_pressed():
	print("Join button pressed")
	var address = server_address_input.text if server_address_input else "127.0.0.1"
	update_status("Connecting to " + address + "...")
	
	# Use the existing multiplayer system
	var multiplayer_node = get_node_or_null("/root/Multiplayer")
	if multiplayer_node and multiplayer_node.has_method("_on_connect_pressed"):
		# Set the server address in the multiplayer node
		var remote_input = multiplayer_node.get_node_or_null("UI/Net/Options/Remote")
		if remote_input:
			remote_input.text = address
		
		multiplayer_node._on_connect_pressed()
		# Transition to game
		start_game()
	else:
		update_status("Error: Could not connect")

func _on_back_pressed():
	print("Back button pressed")
	# Go back to main menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_main_menu"):
		game_root.show_main_menu()

func start_game():
	update_status("Starting game...")
	# Transition to playing state
	var game_root = get_parent()
	if game_root and game_root.has_method("show_hud"):
		game_root.show_hud()
		game_root.start_multiplayer_game()

func create_simple_multiplayer():
	# Create a simple multiplayer setup for testing
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(4433)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		update_status("Error: Failed to start server")
		return
	multiplayer.multiplayer_peer = peer
	update_status("Server started successfully")

func update_status(message: String):
	if status_label:
		status_label.text = message
	print("Lobby Status: " + message)

func update_player_list():
	# Clear current list
	for child in player_list.get_children():
		child.queue_free()
	
	# Add players
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		var player_label = Label.new()
		player_label.text = "Player " + str(player.player)
		player_list.add_child(player_label)

# Input handling
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed() 
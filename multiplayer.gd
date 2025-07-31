extends Node

const PORT = 4433

# Lobby setup variables
var is_hosting_from_lobby = false
var server_address_from_lobby = ""

func _ready():
	# Start paused
	get_tree().paused = true
	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server")
		_on_host_pressed.call_deferred()

# Setup method called from lobby screen
func setup_from_lobby(is_hosting: bool, server_address: String = ""):
	print("Multiplayer: Setup from lobby - Hosting: ", is_hosting, " Address: ", server_address)
	is_hosting_from_lobby = is_hosting
	server_address_from_lobby = server_address
	
	# Set the server address in the UI if joining
	if not is_hosting and server_address != "":
		var remote_input = get_node_or_null("UI/Net/Options/Remote")
		if remote_input:
			remote_input.text = server_address
			print("Multiplayer: Set server address to: ", server_address)
	
	# Automatically start hosting or connecting
	if is_hosting:
		_on_host_pressed.call_deferred()
	else:
		_on_connect_pressed.call_deferred()

func _on_host_pressed():
	# Start as server
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func _on_connect_pressed():
	# Start as client
	var txt : String = $UI/Net/Options/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	get_tree().paused = false
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load("res://level.tscn"))


# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())

# The server can restart the level by pressing HOME.
func _input(event):
	# Note: Pause menu handling is now managed by InputHandler
	
	# Server-only input
	if not multiplayer.is_server():
		return
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		change_level.call_deferred(load("res://level.tscn"))

func toggle_pause_menu():
	print("[Multiplayer] toggle_pause_menu() called")
	var pause_menu = get_node_or_null("PauseMenu")
	print("[Multiplayer] pause_menu found: ", pause_menu != null)
	if pause_menu:
		print("[Multiplayer] pause_menu.visible before: ", pause_menu.visible)
		if pause_menu.visible:
			# Hide pause menu and resume game
			pause_menu.visible = false
			# Don't unpause in multiplayer - just hide the menu
			if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
				get_tree().paused = false
		else:
			# Show pause menu but don't pause the game in multiplayer
			pause_menu.visible = true
			# Only pause if not in multiplayer
			if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
				get_tree().paused = true
			# Grab focus for keyboard navigation
			var resume_button = pause_menu.get_node_or_null("VBoxContainer/ResumeButton")
			if resume_button:
				resume_button.grab_focus()
		print("[Multiplayer] pause_menu.visible after: ", pause_menu.visible)
	else:
		print("[Multiplayer] ERROR: PauseMenu node not found!")

# Public methods for console interaction
func connect_to_server(ip: String, port: int):
	print("Multiplayer: Console requested connection to ", ip, ":", port)
	
	# Disconnect if already connected
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		multiplayer.multiplayer_peer.close()
	
	# Create new client connection
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Multiplayer: Failed to create client connection")
		return false
	
	multiplayer.multiplayer_peer = peer
	print("Multiplayer: Client connection created successfully")
	return true

func host_server(port: int):
	print("Multiplayer: Console requested hosting on port ", port)
	
	# Disconnect if already connected
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		multiplayer.multiplayer_peer.close()
	
	# Create new server
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Multiplayer: Failed to create server")
		return false
	
	multiplayer.multiplayer_peer = peer
	print("Multiplayer: Server created successfully on port ", port)
	return true

func disconnect_from_server():
	print("Multiplayer: Console requested disconnection")
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		print("Multiplayer: Disconnected from server")

func show_network_status():
	var status = "Network Status:\n"
	
	if not multiplayer.multiplayer_peer:
		status += "  Not connected\n"
	else:
		var connection_status = multiplayer.multiplayer_peer.get_connection_status()
		match connection_status:
			MultiplayerPeer.CONNECTION_DISCONNECTED:
				status += "  Disconnected\n"
			MultiplayerPeer.CONNECTION_CONNECTING:
				status += "  Connecting...\n"
			MultiplayerPeer.CONNECTION_CONNECTED:
				status += "  Connected\n"
		
		if multiplayer.is_server():
			status += "  Role: Server\n"
			status += "  Port: " + str(multiplayer.multiplayer_peer.get_local_port()) + "\n"
			status += "  Connected peers: " + str(multiplayer.get_peers().size()) + "\n"
		else:
			status += "  Role: Client\n"
			status += "  Server: " + str(multiplayer.multiplayer_peer.get_remote_address()) + ":" + str(multiplayer.multiplayer_peer.get_remote_port()) + "\n"
	
	print("Multiplayer: ", status)
	
	# Also log to console if available
	var console = find_console()
	if console:
		console.log(status, Color.CYAN)

# Helper function to find console
func find_console():
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameRoot":
			var console = child.get_node_or_null("Console")
			if console:
				return console
	return null

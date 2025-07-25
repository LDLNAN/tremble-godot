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
	if not multiplayer.is_server():
		return
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		change_level.call_deferred(load("res://level.tscn"))

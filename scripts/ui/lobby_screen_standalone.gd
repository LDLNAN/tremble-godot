extends Control
class_name LobbyScreenStandalone

# Standalone Lobby Screen - Handles multiplayer hosting and joining

# UI References
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var server_address_input: LineEdit = $VBoxContainer/ServerAddressInput
@onready var back_button: Button = $BackButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

func _ready():
	print("LobbyScreenStandalone: _ready() called")
	
	# Connect buttons
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Set default server address
	server_address_input.text = "127.0.0.1"
	
	# Update status
	update_status("Ready to host or join")
	
	print("LobbyScreenStandalone: _ready() completed")

func _on_host_pressed():
	print("Host button pressed")
	update_status("Starting server...")
	
	# Transition to multiplayer scene for hosting
	start_multiplayer_game(true)

func _on_join_pressed():
	print("Join button pressed")
	
	# Get server address
	var server_address = server_address_input.text.strip_edges()
	
	if server_address == "":
		OS.alert("Please enter a server address")
		return
	
	update_status("Connecting to " + server_address + "...")
	
	# Transition to multiplayer scene for joining
	start_multiplayer_game(false, server_address)

func _on_back_pressed():
	print("Back button pressed")
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu_standalone.tscn")

func update_status(message: String):
	status_label.text = message
	print("LobbyScreenStandalone: Status updated: ", message)

func start_multiplayer_game(is_hosting: bool, server_address: String = ""):
	print("Starting multiplayer game...")
	update_status("Loading multiplayer scene...")
	
	# Load the multiplayer scene
	var multiplayer_scene = load("res://multiplayer.tscn")
	if multiplayer_scene:
		# Change to the multiplayer scene
		get_tree().change_scene_to_file("res://multiplayer.tscn")
		
		# The multiplayer scene will handle the setup in its _ready() function
		# We'll pass the hosting/joining info through a global variable or signal
		# For now, we'll let the multiplayer scene handle it
		print("LobbyScreenStandalone: Multiplayer scene loaded")
	else:
		print("ERROR: Failed to load multiplayer scene")
		update_status("Failed to load game")

# Input handling for keyboard navigation
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Handle escape key - go back to main menu
		print("Escape key pressed in lobby screen")
		_on_back_pressed() 
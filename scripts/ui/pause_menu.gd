extends Control
class_name PauseMenu

# Pause Menu - In-game pause functionality

# UI References
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var disconnect_button: Button = $VBoxContainer/DisconnectButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready():
	# Set up button connections
	setup_connections()
	
	# Grab focus for keyboard navigation
	resume_button.grab_focus()

func setup_connections():
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if disconnect_button:
		disconnect_button.pressed.connect(_on_disconnect_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed():
	print("Resume button pressed")
	# Resume the game
	var game_root = get_parent()
	if game_root and game_root.has_method("show_hud"):
		game_root.show_hud()
		get_tree().paused = false

func _on_options_pressed():
	print("Options button pressed")
	# Go to options menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_options_menu"):
		game_root.show_options_menu()

func _on_disconnect_pressed():
	print("Disconnect button pressed")
	# Disconnect from multiplayer
	disconnect_from_game()

func _on_main_menu_pressed():
	print("Main menu button pressed")
	# Go back to main menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_main_menu"):
		game_root.show_main_menu()
		get_tree().paused = false

func disconnect_from_game():
	# Disconnect from multiplayer
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	
	# Return to main menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_main_menu"):
		game_root.show_main_menu()
		get_tree().paused = false

# Input handling
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed() 
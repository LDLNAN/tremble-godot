extends Control
class_name MainMenu

# Main Menu - Entry point for the game

# UI References
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var leaderboard_button: Button = $VBoxContainer/LeaderboardButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel

# Game version
const GAME_VERSION = "0.1.0"

func _ready():
	print("MainMenu: _ready() called")
	
	# Set up button connections
	print("MainMenu: Setting up connections...")
	setup_connections()
	
	# Set version label
	if version_label:
		version_label.text = "v" + GAME_VERSION
		print("MainMenu: Version label set")
	else:
		print("WARNING: MainMenu version_label not found")
	
	# Set title
	if title_label:
		title_label.text = "TREMBLE"
		print("MainMenu: Title label set")
	else:
		print("WARNING: MainMenu title_label not found")
	
	# Grab focus for keyboard navigation
	if play_button:
		play_button.grab_focus()
		print("MainMenu: Focus set to play button")
	else:
		print("WARNING: MainMenu play_button not found")
	
	print("MainMenu: _ready() completed")

func setup_connections():
	print("MainMenu: Connecting play button...")
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		print("MainMenu: Play button connected")
	else:
		print("ERROR: MainMenu play_button not found")
	
	print("MainMenu: Connecting options button...")
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
		print("MainMenu: Options button connected")
	else:
		print("ERROR: MainMenu options_button not found")
	
	print("MainMenu: Connecting leaderboard button...")
	if leaderboard_button:
		leaderboard_button.pressed.connect(_on_leaderboard_pressed)
		print("MainMenu: Leaderboard button connected")
	else:
		print("ERROR: MainMenu leaderboard_button not found")
	
	print("MainMenu: Connecting quit button...")
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		print("MainMenu: Quit button connected")
	else:
		print("ERROR: MainMenu quit_button not found")

func _on_play_pressed():
	print("Play button pressed - transitioning to lobby")
	# Transition to lobby screen
	var game_root = get_parent()
	if game_root and game_root.has_method("show_lobby_screen"):
		game_root.show_lobby_screen()

func _on_options_pressed():
	print("Options button pressed")
	# Transition to options menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_options_menu"):
		game_root.show_options_menu()

func _on_leaderboard_pressed():
	print("Leaderboard button pressed")
	# TODO: Implement leaderboard screen
	# For now, just show a placeholder message
	OS.alert("Leaderboard coming soon!", "Feature Not Available")

func _on_quit_pressed():
	print("Quit button pressed")
	# Quit the game
	get_tree().quit()

# Input handling for keyboard navigation
func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Handle enter key on focused button
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.pressed.emit()
	
	elif event.is_action_pressed("ui_cancel"):
		# Handle escape key
		_on_quit_pressed()

# Animation functions (for future polish)
func play_enter_animation():
	# TODO: Add entrance animation
	pass

func play_exit_animation():
	# TODO: Add exit animation
	pass 
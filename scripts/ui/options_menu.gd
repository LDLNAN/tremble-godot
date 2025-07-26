extends Control
class_name OptionsMenu

# Options Menu - Handles game settings and configuration

# UI References
@onready var graphics_button: Button = $VBoxContainer/GraphicsButton
@onready var audio_button: Button = $VBoxContainer/AudioButton
@onready var controls_button: Button = $VBoxContainer/ControlsButton
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready():
	# Set up button connections
	setup_connections()
	
	# Grab focus for keyboard navigation
	graphics_button.grab_focus()

func setup_connections():
	if graphics_button:
		graphics_button.pressed.connect(_on_graphics_pressed)
	if audio_button:
		audio_button.pressed.connect(_on_audio_pressed)
	if controls_button:
		controls_button.pressed.connect(_on_controls_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_graphics_pressed():
	print("Graphics button pressed")
	# TODO: Show graphics settings submenu
	# For now, just print a message
	print("Graphics settings not yet implemented")

func _on_audio_pressed():
	print("Audio button pressed")
	# TODO: Show audio settings submenu
	# For now, just print a message
	print("Audio settings not yet implemented")

func _on_controls_pressed():
	print("Controls button pressed")
	# TODO: Show controls settings submenu
	# For now, just print a message
	print("Controls settings not yet implemented")

func _on_back_pressed():
	print("Back button pressed")
	# Go back to previous screen
	var game_root = get_parent()
	if game_root and game_root.has_method("go_back"):
		game_root.go_back() 
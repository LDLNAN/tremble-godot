extends Control
class_name PauseMenu

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var disconnect_button: Button = $VBoxContainer/DisconnectButton
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

# Options menu references
@onready var universal_options_menu: Control = $UniversalOptionsMenu
@onready var options_back_button: Button = $UniversalOptionsMenu/BackButton
@onready var audio_tab_button: Button = $UniversalOptionsMenu/OptionsContainer/TabButtons/AudioTabButton
@onready var video_tab_button: Button = $UniversalOptionsMenu/OptionsContainer/TabButtons/VideoTabButton
@onready var controls_tab_button: Button = $UniversalOptionsMenu/OptionsContainer/TabButtons/ControlsTabButton

# Options content areas
@onready var audio_content: VBoxContainer = $UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent
@onready var video_content: VBoxContainer = $UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent
@onready var controls_content: VBoxContainer = $UniversalOptionsMenu/OptionsContainer/ContentArea/ControlsContent

func _ready():
	print("=== PAUSE MENU _READY() CALLED ===")
	
	# Set up input processing
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	
	# Connect options menu buttons
	options_back_button.pressed.connect(_on_options_back_pressed)
	audio_tab_button.pressed.connect(_on_audio_tab_pressed)
	video_tab_button.pressed.connect(_on_video_tab_pressed)
	controls_tab_button.pressed.connect(_on_controls_tab_pressed)
	
	resume_button.grab_focus()
	print("=== PAUSE MENU _READY() COMPLETED - BUTTONS CONNECTED ===")

func _on_resume_pressed():
	print("=== RESUME BUTTON PRESSED ===")
	print("=== PAUSE MENU VISIBLE BEFORE: ", visible, " ===")
	visible = false
	# Restore mouse capture for gameplay
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("=== PAUSE MENU VISIBLE AFTER: ", visible, " ===")
	# Only unpause if not in multiplayer
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		get_tree().paused = false

func _on_options_pressed():
	print("=== OPTIONS BUTTON PRESSED ===")
	show_options_menu()

func _on_options_back_pressed():
	print("=== OPTIONS BACK BUTTON PRESSED ===")
	hide_options_menu()

func _on_audio_tab_pressed():
	print("=== AUDIO TAB PRESSED ===")
	show_options_tab(audio_content)

func _on_video_tab_pressed():
	print("=== VIDEO TAB PRESSED ===")
	show_options_tab(video_content)

func _on_controls_tab_pressed():
	print("=== CONTROLS TAB PRESSED ===")
	show_options_tab(controls_content)

func show_options_menu():
	universal_options_menu.visible = true
	# Show audio tab by default
	show_options_tab(audio_content)

func hide_options_menu():
	universal_options_menu.visible = false

func show_options_tab(content_to_show: Control):
	# Hide all content areas
	audio_content.visible = false
	video_content.visible = false
	controls_content.visible = false
	
	# Show the selected content
	content_to_show.visible = true

func _on_disconnect_pressed():
	print("=== DISCONNECT BUTTON PRESSED ===")
	
	# Show confirmation dialog
	show_confirmation_dialog(
		"Disconnect",
		"Are you sure you want to disconnect from the server?",
		"Cancel",
		"Disconnect",
		_on_disconnect_confirmed
	)

func _on_disconnect_confirmed():
	print("=== DISCONNECT CONFIRMED ===")
	
	# Unpause the game first
	get_tree().paused = false
	
	# Disconnect from multiplayer if possible
	if multiplayer and multiplayer.multiplayer_peer:
		print("[PauseMenu] Closing multiplayer peer")
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Change scene back to main menu
	print("[PauseMenu] Changing scene to main menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu_standalone.tscn")



func _input(event):
	# Only process input when visible
	if not visible:
		return
		
	# Handle button clicks and other UI interactions
	print("=== PAUSE MENU _INPUT CALLED ===")
	print("=== INPUT EVENT: ", event, " ===")
	
	# Handle Escape key to close menu
	if event.is_action_pressed("ui_cancel"):
		print("=== PAUSE MENU ESCAPE KEY PRESSED ===")
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
		return

# Dialog utility function for pause menu
func show_confirmation_dialog(title: String, message: String, cancel_text: String = "Cancel", confirm_text: String = "Confirm", on_confirm: Callable = Callable(), on_cancel: Callable = Callable()):
	# Configure the dialog
	confirmation_dialog.title = title
	confirmation_dialog.dialog_text = message
	
	# Connect callbacks
	if on_confirm.is_valid():
		confirmation_dialog.confirmed.connect(on_confirm, CONNECT_ONE_SHOT)
	if on_cancel.is_valid():
		confirmation_dialog.canceled.connect(on_cancel, CONNECT_ONE_SHOT)
	
	# Show the dialog
	confirmation_dialog.popup_centered() 

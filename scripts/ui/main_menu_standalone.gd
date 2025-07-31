extends Control
class_name MainMenuStandalone

# Standalone Main Menu - Handles scene transitions

# Menu history tracking
var menu_history: Array[String] = []
var current_menu: String = "main"

# UI References
@onready var play_button: Button = $TabPanel/PlayButton
@onready var options_button: Button = $TabPanel/OptionsButton
@onready var exit_button: Button = $TabPanel/ExitButton

# Sub-menu references
@onready var play_choice_menu: Control = $PlayChoiceMenu
@onready var single_player_menu: Control = $SinglePlayerMenu
@onready var lobby_menu: Control = $LobbyMenu
@onready var universal_options_menu: Control = $UniversalOptionsMenu

# Play choice menu buttons
@onready var single_player_button: Button = $PlayChoiceMenu/MenuContainer/ButtonContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $PlayChoiceMenu/MenuContainer/ButtonContainer/MultiplayerButton
@onready var play_choice_back_button: Button = $PlayChoiceMenu/BackButton

# Single player menu buttons
@onready var quick_play_button: Button = $SinglePlayerMenu/MenuContainer/ButtonContainer/QuickPlayButton
@onready var custom_game_button: Button = $SinglePlayerMenu/MenuContainer/ButtonContainer/CustomGameButton
@onready var single_player_back_button: Button = $SinglePlayerMenu/BackButton

# Lobby menu buttons
@onready var lobby_back_button: Button = $LobbyMenu/BackButton
@onready var host_button: Button = $LobbyMenu/VBoxContainer/HostButton
@onready var join_button: Button = $LobbyMenu/VBoxContainer/JoinButton
@onready var server_address_input: LineEdit = $LobbyMenu/VBoxContainer/ServerAddressInput
@onready var status_label: Label = $LobbyMenu/VBoxContainer/StatusLabel

# Options menu buttons
@onready var options_back_button: Button = $UniversalOptionsMenu/BackButton
@onready var audio_tab_button: Button = $UniversalOptionsMenu/OptionsContainer/TabButtons/AudioTabButton
@onready var video_tab_button: Button = $UniversalOptionsMenu/OptionsContainer/TabButtons/VideoTabButton
@onready var controls_tab_button: Button = $UniversalOptionsMenu/OptionsContainer/TabButtons/ControlsTabButton

# Options content areas
@onready var audio_content: VBoxContainer = $UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent
@onready var video_content: VBoxContainer = $UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent
@onready var controls_content: VBoxContainer = $UniversalOptionsMenu/OptionsContainer/ContentArea/ControlsContent

# Dialog reference
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

func _ready():
	print("MainMenuStandalone: _ready() called")
	
	# Connect main menu buttons
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Connect play choice menu buttons
	single_player_button.pressed.connect(_on_single_player_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	play_choice_back_button.pressed.connect(_on_play_choice_back_pressed)
	
	# Connect single player menu buttons
	quick_play_button.pressed.connect(_on_quick_play_pressed)
	custom_game_button.pressed.connect(_on_custom_game_pressed)
	single_player_back_button.pressed.connect(_on_single_player_back_pressed)
	
	# Connect lobby menu buttons
	lobby_back_button.pressed.connect(_on_lobby_back_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	# Connect options menu buttons
	options_back_button.pressed.connect(_on_options_back_pressed)
	audio_tab_button.pressed.connect(_on_audio_tab_pressed)
	video_tab_button.pressed.connect(_on_video_tab_pressed)
	controls_tab_button.pressed.connect(_on_controls_tab_pressed)
	
	# Show main menu by default
	show_main_menu()
	
	print("MainMenuStandalone: _ready() completed")

# Main menu functions
func _on_play_pressed():
	print("Play button pressed")
	show_menu("play_choice")

func _on_options_pressed():
	print("Options button pressed")
	show_menu("options")

func _on_exit_pressed():
	print("Exit button pressed")
	get_tree().quit()

# Play choice menu functions
func _on_single_player_pressed():
	print("Single Player button pressed")
	show_menu("single_player")

func _on_multiplayer_pressed():
	print("Multiplayer button pressed")
	show_menu("lobby")

func _on_play_choice_back_pressed():
	print("Play choice back button pressed")
	go_back()

# Single player menu functions
func _on_quick_play_pressed():
	print("Quick Play button pressed")
	# Start single player game
	get_tree().change_scene_to_file("res://single_player.tscn")

func _on_custom_game_pressed():
	print("Custom Game button pressed")
	# Start custom single player game
	get_tree().change_scene_to_file("res://single_player.tscn")

func _on_single_player_back_pressed():
	print("Single player back button pressed")
	go_back()

# Lobby menu functions
func _on_lobby_back_pressed():
	print("Lobby back button pressed")
	go_back()

func _on_host_pressed():
	print("Host button pressed")
	update_status("Starting server...")
	start_multiplayer_game(true)

func _on_join_pressed():
	print("Join button pressed")
	
	# Get server address
	var server_address = server_address_input.text.strip_edges()
	
	if server_address == "":
		OS.alert("Please enter a server address")
		return
	
	update_status("Connecting to " + server_address + "...")
	start_multiplayer_game(false, server_address)

func update_status(message: String):
	status_label.text = message
	print("MainMenuStandalone: Status updated: ", message)

# Dialog utility function
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

func start_multiplayer_game(is_hosting: bool, server_address: String = ""):
	print("Starting multiplayer game...")
	update_status("Setting up multiplayer connection...")
	
	# Set up multiplayer connection directly
	if is_hosting:
		# Start as server
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(4433)  # Use the same port as in multiplayer.gd
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			OS.alert("Failed to start multiplayer server")
			update_status("Failed to start server")
			return
		multiplayer.multiplayer_peer = peer
		update_status("Server started successfully")
	else:
		# Start as client
		if server_address == "":
			OS.alert("Please enter a server address")
			update_status("No server address provided")
			return
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(server_address, 4433)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			OS.alert("Failed to connect to server")
			update_status("Failed to connect")
			return
		multiplayer.multiplayer_peer = peer
		update_status("Connecting to server...")
	
	# Load the actual game scene (level.tscn) instead of the old multiplayer scene
	update_status("Loading game...")
	get_tree().change_scene_to_file("res://level.tscn")

# Options menu functions
func _on_options_back_pressed():
	print("Options back button pressed")
	go_back()

func _on_audio_tab_pressed():
	print("Audio tab pressed")
	show_options_tab(audio_content)

func _on_video_tab_pressed():
	print("Video tab pressed")
	show_options_tab(video_content)

func _on_controls_tab_pressed():
	print("Controls tab pressed")
	show_options_tab(controls_content)

# Menu history and navigation functions
func go_back():
	if menu_history.size() > 0:
		var previous_menu = menu_history.pop_back()
		# Don't add to history when going back
		current_menu = previous_menu
		match previous_menu:
			"main":
				show_main_menu()
			"play_choice":
				show_play_choice_menu()
			"single_player":
				show_single_player_menu()
			"lobby":
				show_lobby_menu()
			"options":
				show_universal_options_menu()
	else:
		# If no history, go to main menu
		show_main_menu()

func show_menu(menu_name: String):
	# Add current menu to history before changing
	if current_menu != "main":
		menu_history.append(current_menu)
	
	current_menu = menu_name
	
	match menu_name:
		"main":
			show_main_menu()
		"play_choice":
			show_play_choice_menu()
		"single_player":
			show_single_player_menu()
		"lobby":
			show_lobby_menu()
		"options":
			show_universal_options_menu()

# Menu visibility functions
func show_main_menu():
	play_choice_menu.visible = false
	single_player_menu.visible = false
	lobby_menu.visible = false
	universal_options_menu.visible = false
	current_menu = "main"

func show_play_choice_menu():
	play_choice_menu.visible = true
	single_player_menu.visible = false
	lobby_menu.visible = false
	universal_options_menu.visible = false
	current_menu = "play_choice"

func show_single_player_menu():
	play_choice_menu.visible = false
	single_player_menu.visible = true
	lobby_menu.visible = false
	universal_options_menu.visible = false
	current_menu = "single_player"

func show_lobby_menu():
	play_choice_menu.visible = false
	single_player_menu.visible = false
	lobby_menu.visible = true
	universal_options_menu.visible = false
	current_menu = "lobby"
	# Set default server address
	server_address_input.text = "127.0.0.1"
	update_status("Ready to host or join")

func show_universal_options_menu():
	play_choice_menu.visible = false
	single_player_menu.visible = false
	lobby_menu.visible = false
	universal_options_menu.visible = true
	current_menu = "options"
	# Show audio tab by default
	show_options_tab(audio_content)

func show_options_tab(content_to_show: Control):
	# Hide all content areas
	audio_content.visible = false
	video_content.visible = false
	controls_content.visible = false
	
	# Show the selected content
	content_to_show.visible = true 

extends Control

# Main Menu - Entry point for the game (Safe version)

# UI References (not using @onready to avoid initialization issues)
var play_tab: Button
var options_tab: Button
var leaderboard_tab: Button
var exit_tab: Button
var title_label: Label
var version_label: Label

# Sub-menus (full screen)
var play_choice_menu: Control
var single_player_menu: Control
var universal_options_menu: Control

# Play choice menu buttons
var single_player_choice_button: Button
var multiplayer_choice_button: Button
var play_choice_back_button: Button

# Single player menu buttons
var quick_play_button: Button
var custom_game_button: Button
var single_player_back_button: Button

# Universal options menu controls
var audio_tab: Button
var video_tab: Button
var controls_tab: Button
var gameplay_tab: Button
var options_back_button: Button

# Options content panels
var audio_content: Control
var video_content: Control
var controls_content: Control
var gameplay_content: Control

# Audio controls
var master_volume_slider: HSlider
var music_volume_slider: HSlider
var sfx_volume_slider: HSlider
var voice_volume_slider: HSlider

# Video controls
var resolution_option: OptionButton
var fullscreen_checkbox: CheckBox
var vsync_checkbox: CheckBox
var graphics_quality_option: OptionButton

# Controls controls
var mouse_sensitivity_slider: HSlider
var invert_mouse_checkbox: CheckBox
var raw_input_checkbox: CheckBox

# Gameplay controls
var fov_slider: HSlider
var crosshair_option: OptionButton
var hud_checkbox: CheckBox

# Game version
const GAME_VERSION = "0.1.0"

func _ready():
	print("MainMenu Safe: _ready() called")
	
	# Wait one frame to ensure all nodes are properly instantiated
	await get_tree().process_frame
	
	# Find UI references safely
	find_ui_references()
	
	# Set up button connections
	print("MainMenu Safe: Setting up connections...")
	setup_connections()
	
	# Set version label
	if version_label:
		version_label.text = "v" + GAME_VERSION
		print("MainMenu Safe: Version label set")
	else:
		print("WARNING: MainMenu Safe version_label not found")
	
	# Set title
	if title_label:
		title_label.text = "TREMBLE"
		print("MainMenu Safe: Title label set")
	else:
		print("WARNING: MainMenu Safe title_label not found")
	
	# Show main menu with proper mouse_filter settings
	show_main_menu()
	
	# Grab focus for keyboard navigation
	if play_tab:
		play_tab.grab_focus()
		print("MainMenu Safe: Focus set to play tab")
	else:
		print("WARNING: MainMenu Safe play_tab not found")
	
	print("MainMenu Safe: _ready() completed")

func find_ui_references():
	# Find main tab buttons
	play_tab = get_node_or_null("TabPanel/PlayTab")
	options_tab = get_node_or_null("TabPanel/OptionsTab")
	leaderboard_tab = get_node_or_null("TabPanel/LeaderboardTab")
	exit_tab = get_node_or_null("TabPanel/ExitTab")
	
	# Find sub-menus
	play_choice_menu = get_node_or_null("PlayChoiceMenu")
	single_player_menu = get_node_or_null("SinglePlayerMenu")
	universal_options_menu = get_node_or_null("UniversalOptionsMenu")
	
	# Find play choice menu buttons
	single_player_choice_button = get_node_or_null("PlayChoiceMenu/MenuContainer/ButtonContainer/SinglePlayerButton")
	multiplayer_choice_button = get_node_or_null("PlayChoiceMenu/MenuContainer/ButtonContainer/MultiplayerButton")
	play_choice_back_button = get_node_or_null("PlayChoiceMenu/BackButton")
	
	# Find single player menu buttons
	quick_play_button = get_node_or_null("SinglePlayerMenu/MenuContainer/ButtonContainer/QuickPlayButton")
	custom_game_button = get_node_or_null("SinglePlayerMenu/MenuContainer/ButtonContainer/CustomGameButton")
	single_player_back_button = get_node_or_null("SinglePlayerMenu/BackButton")
	
	# Find universal options menu controls
	audio_tab = get_node_or_null("UniversalOptionsMenu/OptionsContainer/TabBar/AudioTab")
	video_tab = get_node_or_null("UniversalOptionsMenu/OptionsContainer/TabBar/VideoTab")
	controls_tab = get_node_or_null("UniversalOptionsMenu/OptionsContainer/TabBar/ControlsTab")
	gameplay_tab = get_node_or_null("UniversalOptionsMenu/OptionsContainer/TabBar/GameplayTab")
	options_back_button = get_node_or_null("UniversalOptionsMenu/BackButton")
	
	# Find options content panels
	audio_content = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent")
	video_content = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent")
	controls_content = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/ControlsContent")
	gameplay_content = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/GameplayContent")
	
	# Find audio controls
	master_volume_slider = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent/MasterVolumeSlider")
	music_volume_slider = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent/MusicVolumeSlider")
	sfx_volume_slider = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent/SFXVolumeSlider")
	voice_volume_slider = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/AudioContent/VoiceVolumeSlider")
	
	# Find video controls
	resolution_option = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent/ResolutionOption")
	fullscreen_checkbox = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent/FullscreenCheckBox")
	vsync_checkbox = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent/VSyncCheckBox")
	graphics_quality_option = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/VideoContent/GraphicsQualityOption")
	
	# Find controls controls
	mouse_sensitivity_slider = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/ControlsContent/MouseSensitivitySlider")
	invert_mouse_checkbox = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/ControlsContent/InvertMouseCheckBox")
	raw_input_checkbox = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/ControlsContent/RawInputCheckBox")
	
	# Find gameplay controls
	fov_slider = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/GameplayContent/FOVSlider")
	crosshair_option = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/GameplayContent/CrosshairOption")
	hud_checkbox = get_node_or_null("UniversalOptionsMenu/OptionsContainer/ContentArea/GameplayContent/HUDCheckBox")
	
	# Find labels
	title_label = get_node_or_null("TitleLabel")
	version_label = get_node_or_null("VersionLabel")
	
	print("MainMenu Safe: UI references found:")
	print("  - play_tab: ", play_tab != null)
	print("  - options_tab: ", options_tab != null)
	print("  - leaderboard_tab: ", leaderboard_tab != null)
	print("  - exit_tab: ", exit_tab != null)
	print("  - title_label: ", title_label != null)
	print("  - version_label: ", version_label != null)

func setup_connections():
	# Connect main tab buttons
	print("MainMenu Safe: Connecting main tab buttons...")
	if play_tab:
		play_tab.pressed.connect(_on_play_tab_pressed)
		print("MainMenu Safe: Play tab connected")
	else:
		print("ERROR: MainMenu Safe play_tab not found")
	
	if options_tab:
		options_tab.pressed.connect(_on_options_tab_pressed)
		print("MainMenu Safe: Options tab connected")
	else:
		print("ERROR: MainMenu Safe options_tab not found")
	
	if leaderboard_tab:
		leaderboard_tab.pressed.connect(_on_leaderboard_tab_pressed)
		print("MainMenu Safe: Leaderboard tab connected")
	else:
		print("ERROR: MainMenu Safe leaderboard_tab not found")
	
	if exit_tab:
		exit_tab.pressed.connect(_on_exit_tab_pressed)
		print("MainMenu Safe: Exit tab connected")
	else:
		print("ERROR: MainMenu Safe exit_tab not found")
	
	# Connect play choice menu buttons
	if single_player_choice_button:
		single_player_choice_button.pressed.connect(_on_single_player_choice_pressed)
		print("MainMenu Safe: Single player choice button connected")
	
	if multiplayer_choice_button:
		multiplayer_choice_button.pressed.connect(_on_multiplayer_choice_pressed)
		print("MainMenu Safe: Multiplayer choice button connected")
	
	if play_choice_back_button:
		play_choice_back_button.pressed.connect(_on_back_to_main)
		print("MainMenu Safe: Play choice back button connected")
	
	# Connect single player menu buttons
	if quick_play_button:
		quick_play_button.pressed.connect(_on_quick_play_pressed)
		print("MainMenu Safe: Quick play button connected")
	
	if custom_game_button:
		custom_game_button.pressed.connect(_on_custom_game_pressed)
		print("MainMenu Safe: Custom game button connected")
	
	if single_player_back_button:
		single_player_back_button.pressed.connect(_on_back_to_play_choice)
		print("MainMenu Safe: Single player back button connected")
	
	# Connect universal options menu controls
	if audio_tab:
		audio_tab.pressed.connect(_on_audio_tab_pressed)
		print("MainMenu Safe: Audio tab connected")
	
	if video_tab:
		video_tab.pressed.connect(_on_video_tab_pressed)
		print("MainMenu Safe: Video tab connected")
	
	if controls_tab:
		controls_tab.pressed.connect(_on_controls_tab_pressed)
		print("MainMenu Safe: Controls tab connected")
	
	if gameplay_tab:
		gameplay_tab.pressed.connect(_on_gameplay_tab_pressed)
		print("MainMenu Safe: Gameplay tab connected")
	
	if options_back_button:
		options_back_button.pressed.connect(_on_back_to_main)
		print("MainMenu Safe: Options back button connected")

func show_submenu(submenu_name: String):
	# Hide main menu
	if get_node_or_null("TabPanel"):
		get_node_or_null("TabPanel").visible = false
	
	# Hide all sub-menus
	if play_choice_menu:
		play_choice_menu.visible = false
	if single_player_menu:
		single_player_menu.visible = false
	if universal_options_menu:
		universal_options_menu.visible = false
	
	# Show selected submenu
	match submenu_name:
		"play_choice":
			if play_choice_menu:
				play_choice_menu.visible = true
				print("MainMenu Safe: Showing play choice menu")
		"single_player":
			if single_player_menu:
				single_player_menu.visible = true
				print("MainMenu Safe: Showing single player menu")
		"options":
			if universal_options_menu:
				universal_options_menu.visible = true
				show_options_tab("audio")  # Default to audio tab
				print("MainMenu Safe: Showing universal options menu")

func show_options_tab(tab_name: String):
	# Hide all options content panels
	if audio_content:
		audio_content.visible = false
	if video_content:
		video_content.visible = false
	if controls_content:
		controls_content.visible = false
	if gameplay_content:
		gameplay_content.visible = false
	
	# Show selected tab content
	match tab_name:
		"audio":
			if audio_content:
				audio_content.visible = true
				print("MainMenu Safe: Showing audio options")
		"video":
			if video_content:
				video_content.visible = true
				print("MainMenu Safe: Showing video options")
		"controls":
			if controls_content:
				controls_content.visible = true
				print("MainMenu Safe: Showing controls options")
		"gameplay":
			if gameplay_content:
				gameplay_content.visible = true
				print("MainMenu Safe: Showing gameplay options")

func hide_all_submenus():
	# Show main menu
	if get_node_or_null("TabPanel"):
		get_node_or_null("TabPanel").visible = true
	
	# Hide all sub-menus
	if play_choice_menu:
		play_choice_menu.visible = false
	if single_player_menu:
		single_player_menu.visible = false
	if universal_options_menu:
		universal_options_menu.visible = false

func show_main_menu():
	print("MainMenu Safe: Showing main menu")
	
	# Hide all sub-menus
	if play_choice_menu:
		play_choice_menu.visible = false
		play_choice_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if single_player_menu:
		single_player_menu.visible = false
		single_player_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if universal_options_menu:
		universal_options_menu.visible = false
		universal_options_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Show main tab panel
	var tab_panel = get_node_or_null("TabPanel")
	if tab_panel:
		tab_panel.visible = true
		print("MainMenu Safe: Main menu shown")
	else:
		print("ERROR: MainMenu Safe TabPanel not found")

# Main tab button handlers
func _on_play_tab_pressed():
	print("MainMenu Safe: Play tab pressed")
	show_play_choice_menu()

func _on_options_tab_pressed():
	print("MainMenu Safe: Options tab pressed")
	show_universal_options_menu()

func _on_leaderboard_tab_pressed():
	print("MainMenu Safe: Leaderboard tab pressed")
	# TODO: Implement leaderboard

func _on_exit_tab_pressed():
	print("MainMenu Safe: Exit tab pressed")
	get_tree().quit()

# Sub-menu show functions
func show_play_choice_menu():
	print("MainMenu Safe: Showing play choice menu")
	
	# Hide main tab panel
	var tab_panel = get_node_or_null("TabPanel")
	if tab_panel:
		tab_panel.visible = false
	
	# Hide other sub-menus
	if single_player_menu:
		single_player_menu.visible = false
		single_player_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if universal_options_menu:
		universal_options_menu.visible = false
		universal_options_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Show play choice menu
	if play_choice_menu:
		play_choice_menu.visible = true
		play_choice_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		print("MainMenu Safe: Play choice menu shown")
	else:
		print("ERROR: MainMenu Safe play_choice_menu not found")

func show_single_player_menu():
	print("MainMenu Safe: Showing single player menu")
	
	# Hide main tab panel
	var tab_panel = get_node_or_null("TabPanel")
	if tab_panel:
		tab_panel.visible = false
	
	# Hide other sub-menus
	if play_choice_menu:
		play_choice_menu.visible = false
		play_choice_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if universal_options_menu:
		universal_options_menu.visible = false
		universal_options_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Show single player menu
	if single_player_menu:
		single_player_menu.visible = true
		single_player_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		print("MainMenu Safe: Single player menu shown")
	else:
		print("ERROR: MainMenu Safe single_player_menu not found")

func show_universal_options_menu():
	print("MainMenu Safe: Showing universal options menu")
	
	# Hide main tab panel
	var tab_panel = get_node_or_null("TabPanel")
	if tab_panel:
		tab_panel.visible = false
	
	# Hide other sub-menus
	if play_choice_menu:
		play_choice_menu.visible = false
		play_choice_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if single_player_menu:
		single_player_menu.visible = false
		single_player_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Show universal options menu
	if universal_options_menu:
		universal_options_menu.visible = true
		universal_options_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		print("MainMenu Safe: Universal options menu shown")
	else:
		print("ERROR: MainMenu Safe universal_options_menu not found")

# Play choice menu button handlers
func _on_single_player_choice_pressed():
	print("Single player choice button pressed")
	show_single_player_menu()
	if quick_play_button:
		quick_play_button.grab_focus()

func _on_multiplayer_choice_pressed():
	print("Multiplayer choice button pressed")
	# Go directly to lobby screen
	var game_root = get_parent()
	if game_root and game_root.has_method("show_lobby_screen"):
		game_root.show_lobby_screen()
	else:
		print("ERROR: GameRoot show_lobby_screen method not found")

# Single player menu button handlers
func _on_quick_play_pressed():
	print("Quick play button pressed")
	OS.alert("Quick play coming soon!", "Feature Not Available")

func _on_custom_game_pressed():
	print("Custom game button pressed")
	OS.alert("Custom game coming soon!", "Feature Not Available")

# Universal options tab handlers
func _on_audio_tab_pressed():
	print("Audio tab pressed")
	show_options_tab("audio")

func _on_video_tab_pressed():
	print("Video tab pressed")
	show_options_tab("video")

func _on_controls_tab_pressed():
	print("Controls tab pressed")
	show_options_tab("controls")

func _on_gameplay_tab_pressed():
	print("Gameplay tab pressed")
	show_options_tab("gameplay")

# Back button handlers
func _on_back_to_main():
	print("MainMenu Safe: Back to main pressed")
	show_main_menu()
	if play_tab:
		play_tab.grab_focus()

func _on_back_to_play_choice():
	print("MainMenu Safe: Back to play choice pressed")
	show_play_choice_menu()
	if single_player_choice_button:
		single_player_choice_button.grab_focus()

func _on_back_to_single_player():
	print("MainMenu Safe: Back to single player pressed")
	show_single_player_menu()
	if quick_play_button:
		quick_play_button.grab_focus()

# Input handling for keyboard navigation
func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Handle enter key on focused button
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.pressed.emit()
	
	elif event.is_action_pressed("ui_cancel"):
		# Handle escape key - go back to main menu
		hide_all_submenus()
		if play_tab:
			play_tab.grab_focus()

# Animation functions (for future polish)
func play_enter_animation():
	# TODO: Add entrance animation
	pass

func play_exit_animation():
	# TODO: Add exit animation
	pass 
extends Control
class_name GameRoot

# Add error handling
func _notification(what):
	if what == NOTIFICATION_CRASH:
		print("CRITICAL ERROR: Game crashed!")
		# Try to save any important data
		get_tree().quit()

# Game Root - Coordinates all UI elements and game flow

# UI References
var main_menu: Control
var lobby_screen: Control
var hud: Control
var pause_menu: Control
var match_end_screen: Control
var options_menu: Control

# Game state
var current_ui_state: String = "main_menu"

func _ready():
	print("GameRoot: _ready() called")
	
	# Add basic error handling
	if not is_inside_tree():
		print("ERROR: GameRoot not in scene tree")
		return
	
	# Wait one frame to ensure all nodes are properly instantiated
	print("GameRoot: Waiting for process frame...")
	await get_tree().process_frame
	print("GameRoot: Process frame completed")
	
	# Verify UI references are set up
	print("GameRoot: Verifying UI references...")
	verify_ui_references()
	
	# Set up button connections for pause menu
	print("GameRoot: Setting up pause menu connections...")
	setup_pause_menu_connections()
	
	# Set up button connections for match end screen
	print("GameRoot: Setting up match end connections...")
	setup_match_end_connections()
	
	# Set up button connections for options menu
	print("GameRoot: Setting up options connections...")
	setup_options_connections()
	
	# Start with main menu
	print("GameRoot: Showing main menu...")
	show_main_menu()
	print("GameRoot: _ready() completed successfully")

func verify_ui_references():
	# Debug: Print all direct children of this node
	print("DEBUG: Direct children of GameRoot:")
	for child in get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	# Find UI nodes in the scene tree
	main_menu = get_node_or_null("MainMenu")
	lobby_screen = get_node_or_null("LobbyScreen")
	hud = get_node_or_null("HUD")
	pause_menu = get_node_or_null("PauseMenu")
	match_end_screen = get_node_or_null("MatchEndScreen")
	options_menu = get_node_or_null("OptionsMenu")
	
	# Check if all UI references are properly set
	var missing_ui = []
	
	if not main_menu:
		missing_ui.append("MainMenu")
	if not lobby_screen:
		missing_ui.append("LobbyScreen")
	if not hud:
		missing_ui.append("HUD")
	if not pause_menu:
		missing_ui.append("PauseMenu")
	if not match_end_screen:
		missing_ui.append("MatchEndScreen")
	if not options_menu:
		missing_ui.append("OptionsMenu")
	
	if missing_ui.size() > 0:
		print("WARNING: Missing UI references: ", missing_ui)
		print("This may cause UI navigation issues.")
		print("Attempting to find nodes with alternative paths...")
		
		# Try alternative paths
		if not main_menu:
			main_menu = get_node_or_null("/root/GameRoot/MainMenu")
		if not lobby_screen:
			lobby_screen = get_node_or_null("/root/GameRoot/LobbyScreen")
		if not hud:
			hud = get_node_or_null("/root/GameRoot/HUD")
		if not pause_menu:
			pause_menu = get_node_or_null("/root/GameRoot/PauseMenu")
		if not match_end_screen:
			match_end_screen = get_node_or_null("/root/GameRoot/MatchEndScreen")
		if not options_menu:
			options_menu = get_node_or_null("/root/GameRoot/OptionsMenu")
		
		# Check again after alternative paths
		var still_missing = []
		if not main_menu:
			still_missing.append("MainMenu")
		if not lobby_screen:
			still_missing.append("LobbyScreen")
		if not hud:
			still_missing.append("HUD")
		if not pause_menu:
			still_missing.append("PauseMenu")
		if not match_end_screen:
			still_missing.append("MatchEndScreen")
		if not options_menu:
			still_missing.append("OptionsMenu")
		
		if still_missing.size() > 0:
			print("ERROR: Still missing UI references after alternative paths: ", still_missing)
		else:
			print("SUCCESS: Found all UI references using alternative paths.")
	else:
		print("All UI references verified successfully.")

func setup_pause_menu_connections():
	if not pause_menu:
		print("WARNING: PauseMenu not found, skipping button connections")
		return
		
	var resume_button = pause_menu.get_node_or_null("VBoxContainer/ResumeButton")
	var options_button = pause_menu.get_node_or_null("VBoxContainer/OptionsButton")
	var disconnect_button = pause_menu.get_node_or_null("VBoxContainer/DisconnectButton")
	var main_menu_button = pause_menu.get_node_or_null("VBoxContainer/MainMenuButton")
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if disconnect_button:
		disconnect_button.pressed.connect(_on_disconnect_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func setup_match_end_connections():
	if not match_end_screen:
		print("WARNING: MatchEndScreen not found, skipping button connections")
		return
		
	var rematch_button = match_end_screen.get_node_or_null("VBoxContainer/RematchButton")
	var new_match_button = match_end_screen.get_node_or_null("VBoxContainer/NewMatchButton")
	var main_menu_button = match_end_screen.get_node_or_null("VBoxContainer/MainMenuButton")
	
	if rematch_button:
		rematch_button.pressed.connect(_on_rematch_pressed)
	if new_match_button:
		new_match_button.pressed.connect(_on_new_match_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func setup_options_connections():
	if not options_menu:
		print("WARNING: OptionsMenu not found, skipping button connections")
		return
		
	var back_button = options_menu.get_node_or_null("VBoxContainer/BackButton")
	if back_button:
		back_button.pressed.connect(_on_options_back_pressed)

# UI State Management
func show_main_menu():
	hide_all_ui()
	if main_menu:
		main_menu.show()
		main_menu.grab_focus()
	current_ui_state = "main_menu"

func show_lobby_screen():
	hide_all_ui()
	if lobby_screen:
		lobby_screen.show()
		lobby_screen.grab_focus()
	current_ui_state = "lobby"

func show_hud():
	hide_all_ui()
	if hud:
		hud.show()
	current_ui_state = "hud"

func show_pause_menu():
	hide_all_ui()
	if pause_menu:
		pause_menu.show()
		pause_menu.grab_focus()
	current_ui_state = "pause"

func show_match_end_screen():
	hide_all_ui()
	if match_end_screen:
		match_end_screen.show()
		match_end_screen.grab_focus()
	current_ui_state = "match_end"

func show_options_menu():
	hide_all_ui()
	if options_menu:
		options_menu.show()
		options_menu.grab_focus()
	current_ui_state = "options"

func hide_all_ui():
	if main_menu:
		main_menu.hide()
	if lobby_screen:
		lobby_screen.hide()
	if hud:
		hud.hide()
	if pause_menu:
		pause_menu.hide()
	if match_end_screen:
		match_end_screen.hide()
	if options_menu:
		options_menu.hide()

# Button callbacks
func _on_resume_pressed():
	print("Resume pressed")
	show_hud()
	get_tree().paused = false

func _on_options_pressed():
	print("Options pressed")
	show_options_menu()

func _on_disconnect_pressed():
	print("Disconnect pressed")
	disconnect_from_game()

func _on_main_menu_pressed():
	print("Main menu pressed")
	disconnect_from_game()
	show_main_menu()

func _on_rematch_pressed():
	print("Rematch pressed")
	# TODO: Implement rematch functionality
	show_lobby_screen()

func _on_new_match_pressed():
	print("New match pressed")
	show_lobby_screen()

func _on_options_back_pressed():
	print("Options back pressed")
	# Go back to previous state
	if current_ui_state == "pause":
		show_pause_menu()
	else:
		show_main_menu()

func disconnect_from_game():
	# Disconnect from multiplayer
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	
	# Remove level if it exists
	var level = get_node_or_null("/root/Level")
	if level:
		level.queue_free()
	
	# Unpause game
	get_tree().paused = false

# Input handling
func _input(event):
	# Handle escape key for pause
	if event.is_action_pressed("ui_cancel"):
		match current_ui_state:
			"hud":
				show_pause_menu()
				get_tree().paused = true
			"pause":
				_on_resume_pressed()
			"options":
				_on_options_back_pressed()

# Integration with existing multiplayer system
func start_multiplayer_game():
	print("Starting multiplayer game...")
	show_hud()
	
	# Load the level using the existing multiplayer system
	var multiplayer_node = get_node_or_null("/root/Multiplayer")
	if multiplayer_node and multiplayer_node.has_method("start_game"):
		multiplayer_node.start_game()
	else:
		# Fallback: load level directly
		load_level("res://level.tscn")

func load_level(level_path: String):
	print("Loading level: ", level_path)
	
	# Remove current level if it exists
	var current_level = get_node_or_null("/root/Level")
	if current_level:
		current_level.queue_free()
	
	# Load and instantiate new level
	var level_scene = load(level_path)
	if level_scene:
		var level_instance = level_scene.instantiate()
		level_instance.name = "Level"
		get_tree().root.add_child(level_instance)
		print("Level loaded successfully")
	else:
		print("ERROR: Could not load level: ", level_path)

# Additional methods for UI navigation
func go_back():
	# Go back to previous state
	match current_ui_state:
		"options":
			if current_ui_state == "pause":
				show_pause_menu()
			else:
				show_main_menu()
		"pause":
			show_hud()
		_:
			show_main_menu() 

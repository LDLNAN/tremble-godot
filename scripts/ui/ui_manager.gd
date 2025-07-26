extends Node

# UI Manager - Controls all UI elements and state transitions
# This should be added as an autoload singleton

# Current UI state
var current_state: String = "main_menu"

# UI References
var main_menu: Control
var lobby_screen: Control
var hud: Control
var pause_menu: Control
var match_end_screen: Control
var options_menu: Control

# Game state references
var game_manager: Node
var player_manager: Node

# UI State management
var ui_history: Array[String] = []

func _ready():
	# Find UI references
	find_ui_references()
	
	# Set initial state
	change_ui_state("main_menu")

func find_ui_references():
	# Find UI nodes in the scene tree
	main_menu = get_node_or_null("/root/MainMenu")
	lobby_screen = get_node_or_null("/root/LobbyScreen")
	hud = get_node_or_null("/root/HUD")
	pause_menu = get_node_or_null("/root/PauseMenu")
	match_end_screen = get_node_or_null("/root/MatchEndScreen")
	options_menu = get_node_or_null("/root/OptionsMenu")
	
	# Try alternative paths if not found
	if not main_menu:
		main_menu = get_node_or_null("MainMenu")
	if not lobby_screen:
		lobby_screen = get_node_or_null("LobbyScreen")
	if not hud:
		hud = get_node_or_null("HUD")
	if not pause_menu:
		pause_menu = get_node_or_null("PauseMenu")
	if not match_end_screen:
		match_end_screen = get_node_or_null("MatchEndScreen")
	if not options_menu:
		options_menu = get_node_or_null("OptionsMenu")

func change_ui_state(new_state: String):
	if current_state == new_state:
		return
	
	# Store current state in history
	ui_history.append(current_state)
	
	# Hide all UI elements
	hide_all_ui()
	
	# Show appropriate UI for new state
	match new_state:
		"main_menu":
			show_main_menu()
		"lobby":
			show_lobby_screen()
		"playing":
			show_hud()
		"paused":
			show_pause_menu()
		"match_end":
			show_match_end_screen()
		"options":
			show_options_menu()
	
	current_state = new_state
	print("UI State changed to: ", new_state)

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

func show_main_menu():
	if main_menu:
		main_menu.show()
		main_menu.grab_focus()

func show_lobby_screen():
	if lobby_screen:
		lobby_screen.show()
		lobby_screen.grab_focus()

func show_hud():
	if hud:
		hud.show()

func show_pause_menu():
	if pause_menu:
		pause_menu.show()
		pause_menu.grab_focus()

func show_match_end_screen():
	if match_end_screen:
		match_end_screen.show()
		match_end_screen.grab_focus()

func show_options_menu():
	if options_menu:
		options_menu.show()
		options_menu.grab_focus()

# Navigation functions
func go_back():
	if ui_history.size() > 0:
		var previous_state = ui_history.pop_back()
		change_ui_state(previous_state)

func go_to_main_menu():
	ui_history.clear()
	change_ui_state("main_menu")

# HUD update functions
func update_health_display(health: float, max_health: float, armor: float = 0.0):
	if hud and hud.has_method("update_health"):
		hud.update_health(health, max_health, armor)

func update_ammo_display(current_ammo: int, max_ammo: int):
	if hud and hud.has_method("update_ammo"):
		hud.update_ammo(current_ammo, max_ammo)

func update_score_display(player_score: int, opponent_score: int):
	if hud and hud.has_method("update_score"):
		hud.update_score(player_score, opponent_score)

func update_timer_display(time_remaining: float):
	if hud and hud.has_method("update_timer"):
		hud.update_timer(time_remaining)

# Input handling
func _input(event):
	# Handle escape key for pause menu
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			"playing":
				change_ui_state("paused")
				get_tree().paused = true
			"paused":
				change_ui_state("playing")
				get_tree().paused = false
			"options":
				go_back()

# Game state integration
func set_game_manager(gm: Node):
	game_manager = gm

func set_player_manager(pm: Node):
	player_manager = pm

# Utility functions
func is_in_game() -> bool:
	return current_state == "playing"

func is_paused() -> bool:
	return current_state == "paused" 

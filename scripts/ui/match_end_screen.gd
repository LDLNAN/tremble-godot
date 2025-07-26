extends Control
class_name MatchEndScreen

# Match End Screen - Displays match results and navigation options

# UI References
@onready var match_result_label: Label = $VBoxContainer/MatchResultLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var rematch_button: Button = $VBoxContainer/RematchButton
@onready var new_match_button: Button = $VBoxContainer/NewMatchButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready():
	# Set up button connections
	setup_connections()
	
	# Grab focus for keyboard navigation
	rematch_button.grab_focus()

func setup_connections():
	if rematch_button:
		rematch_button.pressed.connect(_on_rematch_pressed)
	if new_match_button:
		new_match_button.pressed.connect(_on_new_match_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_rematch_pressed():
	print("Rematch button pressed")
	# Start a new match with same players
	var game_root = get_parent()
	if game_root and game_root.has_method("start_multiplayer_game"):
		game_root.start_multiplayer_game()

func _on_new_match_pressed():
	print("New match button pressed")
	# Go to lobby for new match setup
	var game_root = get_parent()
	if game_root and game_root.has_method("show_lobby_screen"):
		game_root.show_lobby_screen()

func _on_main_menu_pressed():
	print("Main menu button pressed")
	# Go back to main menu
	var game_root = get_parent()
	if game_root and game_root.has_method("show_main_menu"):
		game_root.show_main_menu()

# Update match results
func update_match_result(result: String, player_score: int, opponent_score: int):
	if match_result_label:
		match_result_label.text = result
	
	if score_label:
		score_label.text = "Final Score: %d - %d" % [player_score, opponent_score] 
extends Node

# Game Manager - Central game state control
# This should be added as an autoload singleton

# Game state enum
enum GameState {
	MENU,
	LOBBY,
	PLAYING,
	PAUSED,
	MATCH_END
}

# Current game state
var current_state: GameState = GameState.MENU

# Manager references
var ui_manager: Node
var match_manager: Node
var player_manager: Node
var network_manager: Node

# Game configuration
var current_gamemode: GamemodeConfig
var current_map: String = "level.tscn"

# Player data
var local_player: CharacterBody3D
var local_player_id: int = 1

func _ready():
	# Find other managers
	find_managers()
	
	# Set up initial state
	change_game_state(GameState.MENU)

func find_managers():
	# Find UI Manager
	ui_manager = get_node_or_null("/root/UIManager")
	if not ui_manager:
		print("WARNING: UIManager not found!")
	
	# Find other managers (will be created later)
	match_manager = get_node_or_null("/root/MatchManager")
	player_manager = get_node_or_null("/root/PlayerManager")
	network_manager = get_node_or_null("/root/NetworkManager")

func change_game_state(new_state: GameState):
	if current_state == new_state:
		return
	
	print("Game state changing from ", GameState.keys()[current_state], " to ", GameState.keys()[new_state])
	current_state = new_state
	
	# Update UI state
	if ui_manager:
		match new_state:
			GameState.MENU:
				ui_manager.change_ui_state("main_menu")
			GameState.LOBBY:
				ui_manager.change_ui_state("lobby")
			GameState.PLAYING:
				ui_manager.change_ui_state("playing")
			GameState.PAUSED:
				ui_manager.change_ui_state("paused")
			GameState.MATCH_END:
				ui_manager.change_ui_state("match_end")

# Game flow functions
func start_game():
	print("Starting game...")
	change_game_state(GameState.PLAYING)
	
	# Load the level
	load_level(current_map)

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

func pause_game():
	print("Pausing game...")
	change_game_state(GameState.PAUSED)
	get_tree().paused = true

func resume_game():
	print("Resuming game...")
	change_game_state(GameState.PLAYING)
	get_tree().paused = false

func end_game():
	print("Ending game...")
	change_game_state(GameState.MATCH_END)
	
	# Clean up multiplayer
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	
	# Remove level
	var current_level = get_node_or_null("/root/Level")
	if current_level:
		current_level.queue_free()

func return_to_menu():
	print("Returning to menu...")
	change_game_state(GameState.MENU)
	get_tree().paused = false
	
	# Clean up any remaining game state
	end_game()

# Player management
func set_local_player(player: CharacterBody3D):
	local_player = player
	local_player_id = player.player
	print("Local player set: ", local_player_id)

func get_local_player() -> CharacterBody3D:
	return local_player

# Gamemode management
func set_gamemode(gamemode: GamemodeConfig):
	current_gamemode = gamemode
	print("Gamemode set: ", gamemode.gamemode_name)

func get_current_gamemode() -> GamemodeConfig:
	return current_gamemode

# Utility functions
func is_in_game() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func is_in_menu() -> bool:
	return current_state == GameState.MENU

# Input handling
func _input(event):
	# Handle escape key for pause
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameState.PLAYING:
				pause_game()
			GameState.PAUSED:
				resume_game() 
extends Node
class_name PlayerManager

# System references
var player: CharacterBody3D  # The main player node
var player_health: Node
var player_weapons: Node
var player_input: Node

func _ready():
	player = get_parent() as CharacterBody3D
	
	# Check if parent is actually a CharacterBody3D
	if not player:
		print("ERROR: PlayerManager parent is not a CharacterBody3D!")
		return
	
	# Set up all player systems
	setup_player_systems()

func setup_player_systems():
	# Get existing systems (should be created manually)
	player_health = player.get_node_or_null("PlayerManager/PlayerHealth")
	player_weapons = player.get_node_or_null("PlayerManager/PlayerWeapons")
	player_input = player.get_node_or_null("PlayerInput")
	
	# Check if systems exist
	if not player_health:
		print("ERROR: PlayerHealth node not found! Please create it manually under PlayerManager")
	if not player_weapons:
		print("ERROR: PlayerWeapons node not found! Please create it manually under PlayerManager")
	if not player_input:
		print("ERROR: PlayerInput node not found! Please create it manually under Player")
	
	# Set up cross-references
	if player_weapons and player_health:
		player_weapons.player_health = player_health

func get_health_system() -> Node:
	return player_health

func get_weapon_system() -> Node:
	return player_weapons

func get_input_system() -> Node:
	return player_input 
 

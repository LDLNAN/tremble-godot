extends Node
class_name PlayerWeapons

# Weapon slots
var weapon_slots: Dictionary = {}  # weapon_id -> Node
var current_weapon: Node
var current_weapon_id: String = ""

# Gamemode reference
@export var gamemode_config: GamemodeConfig

# References
var player: CharacterBody3D  # Reference to the parent player
var player_health: Node  # Reference to health system
var weapon_holder: Node3D  # Reference to camera weapon holder

func _ready():
	print("PlayerWeapons _ready() called")
	# Get the player (CharacterBody3D) from the scene hierarchy
	player = get_parent().get_parent() as CharacterBody3D
	
	# Check if we found the player
	if not player:
		print("ERROR: PlayerWeapons could not find CharacterBody3D player!")
		return
	
	# Wait a frame to ensure scene is fully loaded
	await get_tree().process_frame
	
	# Set up gamemode config if not provided in inspector
	if not gamemode_config:
		print("No gamemode config provided, creating default")
		setup_default_gamemode()
	else:
		print("Using gamemode config from inspector: ", gamemode_config.gamemode_name)
	
	# Set up weapons after gamemode config is ready
	setup_weapons()

func setup_default_gamemode():
	print("setup_default_gamemode() called")
	# Create a default gamemode config for testing
	gamemode_config = GamemodeConfig.new()
	if not gamemode_config:
		print("ERROR: Failed to create GamemodeConfig!")
		return
		
	gamemode_config.gamemode_name = "Default"
	gamemode_config.starting_weapons = ["beam_gun"]
	gamemode_config.respawn_weapons = ["beam_gun"]
	print("Gamemode config created successfully")
	
	# Create beam gun config
	var beam_config = WeaponConfig.new()
	if not beam_config:
		print("ERROR: Failed to create WeaponConfig!")
		return
		
	beam_config.weapon_id = "beam_gun"
	beam_config.weapon_name = "Beam Gun"
	beam_config.weapon_type = WeaponConfig.WeaponType.HITSCAN
	beam_config.damage = 20.0
	beam_config.fire_rate = 0.05
	beam_config.ammo_capacity = 100

	beam_config.weapon_range = 15.0
	beam_config.beam_chain_count = 3
	beam_config.beam_damage_falloff = 0.7
	beam_config.beam_range = 15.0
	
	gamemode_config.available_weapons = [beam_config]
	print("Beam gun config created successfully")

func setup_weapon_holder():
	# Find the weapon holder that was manually created
	weapon_holder = player.get_node_or_null("SpringArm3D/CameraPivot/Camera3D/WeaponHolder")
	if not weapon_holder:
		print("ERROR: WeaponHolder not found! Please create it manually under Camera3D")
		return
	
	print("Found weapon holder: ", weapon_holder.name)

func setup_weapons():
	print("setup_weapons() called")
	# Find weapon holder
	setup_weapon_holder()
	if not weapon_holder:
		print("No weapon holder found, returning")
		return
	
	# Clear existing weapons
	print("Clearing weapon slots. Current slots: ", weapon_slots.keys())
	for weapon in weapon_slots.values():
		if weapon:
			print("Freeing weapon: ", weapon.name)
			weapon.queue_free()
	weapon_slots.clear()
	print("Weapon slots cleared")
	
	# Find existing beam gun node
	print("Looking for BeamGun under weapon holder: ", weapon_holder.name)
	var children_names = []
	for child in weapon_holder.get_children():
		children_names.append(child.name)
	print("Weapon holder children: ", children_names)
	var beam_gun_node = weapon_holder.get_node_or_null("BeamGun")
	print("BeamGun node found: ", beam_gun_node)
	if beam_gun_node:
		# Use existing beam gun node
		var weapon = beam_gun_node
		if not weapon.has_method("initialize_from_config"):
			# Attach beam gun script if not already attached
			weapon.set_script(load("res://beam_gun.gd"))
		
		weapon.weapon_owner = player
		weapon.initialize_from_config()
		weapon_slots["beam_gun"] = weapon
		weapon.visible = false
		print("Found existing BeamGun node")
		print("Weapon slots now contain: ", weapon_slots.keys())
		print("Weapon parent: ", weapon.get_parent().name if weapon.get_parent() else "NO PARENT!")
		print("Weapon is in scene tree: ", weapon.is_inside_tree())
		
		# Connect to tree_exiting signal to detect when weapon is freed
		if not weapon.tree_exiting.is_connected(_on_weapon_tree_exiting):
			weapon.tree_exiting.connect(_on_weapon_tree_exiting.bind(weapon))
	else:
		print("ERROR: BeamGun node not found! Please create it manually under WeaponHolder")
		# Note: Weapon properties are set in the beam_gun.gd script's initialize_from_config() method
	
	# Set starting weapon
	if not gamemode_config:
		print("ERROR: Gamemode config is null!")
		return
		
	if gamemode_config.starting_weapons.size() > 0:
		print("Setting starting weapon: ", gamemode_config.starting_weapons[0])
		switch_weapon(gamemode_config.starting_weapons[0])
	else:
		print("ERROR: No starting weapons configured!")

func switch_weapon(weapon_id: String):
	print("switch_weapon() called with: ", weapon_id)
	if weapon_id in weapon_slots and weapon_slots[weapon_id]:
		# Check if weapon is still valid
		var weapon = weapon_slots[weapon_id]
		if not is_instance_valid(weapon):
			print("ERROR: Weapon in slots is not valid! Removing from slots.")
			weapon_slots.erase(weapon_id)
			return
		
		# Hide current weapon
		if current_weapon and is_instance_valid(current_weapon):
			current_weapon.visible = false
		
		# Show new weapon
		current_weapon = weapon
		current_weapon_id = weapon_id
		current_weapon.visible = true
		
		print("Switched to weapon: ", weapon_id, " Current weapon: ", current_weapon.name)
	else:
		print("ERROR: Weapon not found in slots: ", weapon_id)

func get_weapon(weapon_id: String) -> Node:
	return weapon_slots.get(weapon_id, null)

func fire_current_weapon():
	print("fire_current_weapon() called")
	print("Current weapon: ", current_weapon)
	print("Weapon slots: ", weapon_slots.keys())
	
	# Check if current weapon is valid
	if current_weapon and is_instance_valid(current_weapon):
		print("Current weapon found: ", current_weapon.name)
		if current_weapon.has_method("fire"):
			print("Weapon has fire method, calling it")
			current_weapon.fire()
		else:
			print("ERROR: Current weapon does not have fire method!")
	else:
		print("ERROR: No current weapon or weapon is invalid!")
		# Try to recover by switching to the first available weapon
		if weapon_slots.size() > 0:
			var first_weapon_id = weapon_slots.keys()[0]
			print("Attempting to recover by switching to: ", first_weapon_id)
			switch_weapon(first_weapon_id)
		else:
			print("No weapons in slots, attempting to recreate beam gun")
			# Try to recreate the beam gun
			setup_weapons()



func respawn_weapons():
	# Give respawn weapons
	for weapon_id in gamemode_config.respawn_weapons:
		give_weapon(weapon_id)
	
	# Switch to first respawn weapon
	if gamemode_config.respawn_weapons.size() > 0:
		switch_weapon(gamemode_config.respawn_weapons[0])

func give_weapon(weapon_id: String):
	if weapon_id in weapon_slots:
		# Weapon already exists
		return
	
	# For now, just handle the beam gun
	if weapon_id == "beam_gun":
		print("ERROR: BeamGun node must be created manually under WeaponHolder")

func _on_weapon_tree_exiting(weapon: Node):
	print("WARNING: Weapon is being freed: ", weapon.name)
	# Remove from slots if it's being freed
	for weapon_id in weapon_slots.keys():
		if weapon_slots[weapon_id] == weapon:
			print("Removing freed weapon from slots: ", weapon_id)
			weapon_slots.erase(weapon_id)
			# Clear current weapon if it's the same
			if current_weapon == weapon:
				print("Clearing current weapon because it was freed")
				current_weapon = null
			break 
 

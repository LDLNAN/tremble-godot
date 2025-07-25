extends Node3D
class_name WeaponBase

# Core properties (set from config)
var weapon_id: String
var weapon_name: String
var damage: float
var fire_rate: float
var ammo_capacity: int

var weapon_range: float
var projectile_speed: float

# Current state
var current_ammo: int
var infinite_ammo: bool = true  # Infinite ammo toggle, on by default

var last_fire_time: float = 0.0
var weapon_owner: CharacterBody3D

# Network sync
@export var networked_ammo: int = 30

# Continuous firing support
var is_continuous_weapon: bool = false
var is_firing_continuous: bool = false

@export var vampirism_amount: float = 0.0  # Per-weapon vampirism (0 = none, 0.2 = 20%)

func _ready():
	# Initialize from config
	initialize_from_config()
	current_ammo = ammo_capacity

func initialize_from_config():
	# Override in subclasses to set weapon-specific properties
	pass

func can_fire() -> bool:
	return (infinite_ammo or current_ammo > 0) and \
		   (Time.get_ticks_msec() / 1000.0) - last_fire_time >= fire_rate

func fire():
	if is_continuous_weapon:
		# For continuous weapons, start firing
		start_continuous_fire()
	else:
		# For single-shot weapons, fire once
		fire_single_shot()

func fire_single_shot():
	if not can_fire():
		return
	
	# Update last fire time
	last_fire_time = Time.get_ticks_msec() / 1000.0
	
	# Server handles firing
	if multiplayer.is_server():
		perform_fire()
		# Only update ammo if not infinite
		if not infinite_ammo:
			update_weapon_state.rpc(current_ammo)

func start_continuous_fire():
	if is_firing_continuous:
		return
	
	is_firing_continuous = true
	perform_start_fire()

func stop_continuous_fire():
	if not is_firing_continuous:
		return
	
	is_firing_continuous = false
	perform_stop_fire()

func perform_fire():
	# Override in subclasses for single-shot weapons
	pass

func perform_start_fire():
	# Override in subclasses for continuous weapons
	pass

func perform_stop_fire():
	# Override in subclasses for continuous weapons
	pass

@rpc("call_local")
func update_weapon_state(ammo: int):
	current_ammo = ammo

func toggle_infinite_ammo():
	infinite_ammo = !infinite_ammo
	print("Infinite ammo: ", "ON" if infinite_ammo else "OFF")

func set_infinite_ammo(enabled: bool):
	infinite_ammo = enabled
	print("Infinite ammo: ", "ON" if infinite_ammo else "OFF")

func get_muzzle_position() -> Vector3:
	# Try to get muzzle position from weapon model
	for child in get_children():
		if child is WeaponModel:
			return child.get_muzzle_global_position()
	
	# Fallback to weapon position
	return global_position 

func apply_vampirism(damage: float):
	# Use both weapon and gamemode multipliers
	var gamemode_vamp := 0.0
	if weapon_owner and weapon_owner.player_manager:
		var weapon_system = weapon_owner.player_manager.get_weapon_system()
		if weapon_system and weapon_system.gamemode_config:
			gamemode_vamp = weapon_system.gamemode_config.vampirism_amount
	
	var total_vamp = vampirism_amount * gamemode_vamp
	if total_vamp > 0.0 and weapon_owner.player_manager:
		var health_node = weapon_owner.player_manager.get_node_or_null("PlayerHealth")
		if health_node and health_node.has_method("heal"):
			var heal_amount = damage * total_vamp
			print("[WEAPONBASE] Vampirism: healing attacker for ", heal_amount)
			health_node.heal(heal_amount) 

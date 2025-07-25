extends Resource
class_name GamemodeConfig

@export var gamemode_name: String = "Default"
@export var max_players: int = 16
@export var time_limit: float = 600.0  # 10 minutes
@export var score_limit: int = 50

# Weapon loadout configuration
@export var available_weapons: Array[WeaponConfig] = []
@export var starting_weapons: Array[String] = ["beam_gun"]
@export var weapon_pickups_enabled: bool = true
@export var respawn_weapons: Array[String] = ["beam_gun"]  # Weapons given on respawn

# Game rules
@export var friendly_fire: bool = false
@export var self_damage: bool = true
@export var weapon_drop_on_death: bool = false 
@export var vampirism_amount: float = 0.2  # Fraction of damage healed to attacker (e.g., 0.2 = 20%) 
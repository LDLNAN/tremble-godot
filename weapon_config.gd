extends Resource
class_name WeaponConfig

@export var weapon_id: String = ""  # Unique identifier
@export var weapon_name: String = ""
@export var weapon_scene: PackedScene
@export var weapon_type: WeaponType = WeaponType.HITSCAN
@export var damage: float = 25.0
@export var fire_rate: float = 0.1
@export var ammo_capacity: int = 30
@export var reload_time: float = 2.0
@export var weapon_range: float = 1000.0
@export var projectile_speed: float = 1000.0

# Weapon-specific properties
@export var beam_range: float = 15.0

enum WeaponType {
	HITSCAN,      # Lightning gun, rail gun
	PROJECTILE,   # Rocket launcher
	MELEE
} 
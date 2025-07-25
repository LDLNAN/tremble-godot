extends Health
class_name PlayerHealth

# Armor system (health is inherited from parent)
@export var max_health: float = 100.0
@export var armor: float = 0.0
@export var max_armor: float = 100.0

# References
var player: CharacterBody3D  # Reference to the parent player

func _ready():
	# Get the player (CharacterBody3D) from the scene hierarchy
	player = get_parent().get_parent() as CharacterBody3D
	
	# Check if we found the player
	if not player:
		print("ERROR: PlayerHealth could not find CharacterBody3D player!")
		return
	
	# Add player to players group for weapon targeting
	if not player.is_in_group("players"):
		player.add_to_group("players")

func take_damage(amount: float, source = null):
	# Apply armor first
	var damage_to_health = amount
	if armor > 0:
		var armor_damage = min(armor, amount * 0.5)  # Armor absorbs 50% of damage
		armor -= armor_damage
		damage_to_health = amount - armor_damage
	
	# Call parent take_damage with the final damage amount
	super.take_damage(damage_to_health, source)
	
	# Clamp health
	health = max(0.0, health)
	
	print("Player took ", damage_to_health, " damage! Health: ", health, " Armor: ", armor)
	
	# Network sync
	if multiplayer.is_server():
		update_health.rpc(health, armor)

@rpc("call_local")
func update_health(new_health: float, new_armor: float):
	health = new_health
	armor = new_armor

# Override die() for custom player death logic
func die():
	# Custom player death logic
	print("Player died!")
	# Don't queue_free() immediately, handle respawn instead
	handle_player_death()

func handle_player_death():
	# Disable player movement temporarily
	if player:
		player.set_physics_process(false)
	
	# Respawn logic
	await get_tree().create_timer(3.0).timeout
	respawn()

func respawn():
	health = max_health
	armor = 0.0
	
	# Reset position (implement respawn point logic)
	if player:
		player.global_position = Vector3(0, 5, 0)
		player.reset_movement_state()
		# Re-enable player movement
		player.set_physics_process(true)
	
	print("Player respawned! Health: ", health)

func heal(amount: float):
	health = min(health + amount, max_health)
	if multiplayer.is_server():
		update_health.rpc(health, armor)

func add_armor(amount: float):
	armor = min(armor + amount, max_armor)
	if multiplayer.is_server():
		update_health.rpc(health, armor) 
 

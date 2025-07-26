extends Control
class_name HUD

# HUD - Displays game information during gameplay

# UI References
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var armor_bar: ProgressBar = $ArmorBar
@onready var armor_label: Label = $ArmorBar/ArmorLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var score_label: Label = $ScoreLabel
@onready var timer_label: Label = $TimerLabel
@onready var crosshair: Control = $Crosshair
@onready var kill_feed: Control = $KillFeed

# Player references
var player: CharacterBody3D
var player_health: PlayerHealth
var player_weapons: PlayerWeapons

# Game state
var player_score: int = 0
var opponent_score: int = 0
var time_remaining: float = 600.0  # 10 minutes default

func _ready():
	# Find player references
	find_player_references()
	
	# Set up initial display
	update_health_display(100.0, 100.0, 0.0)
	update_ammo_display(100, 100)
	update_score_display(0, 0)
	update_timer_display(600.0)

func _process(delta):
	# Update timer
	if time_remaining > 0:
		time_remaining -= delta
		update_timer_display(time_remaining)
	
	# Update player info if available
	if player_health:
		update_health_display(player_health.health, player_health.max_health, player_health.armor)
	
	if player_weapons and player_weapons.current_weapon:
		var weapon = player_weapons.current_weapon
		update_ammo_display(weapon.current_ammo, weapon.ammo_capacity)

func find_player_references():
	# Try to find the local player
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.player == multiplayer.get_unique_id():
			player = p
			player_health = player.get_node_or_null("PlayerHealth")
			player_weapons = player.get_node_or_null("PlayerWeapons")
			break
	
	# If not found, try alternative paths
	if not player:
		player = get_node_or_null("/root/Player")
		if player:
			player_health = player.get_node_or_null("PlayerHealth")
			player_weapons = player.get_node_or_null("PlayerWeapons")

# Update functions
func update_health(health: float, max_health: float, armor: float = 0.0):
	update_health_display(health, max_health, armor)

func update_ammo(current_ammo: int, max_ammo: int):
	update_ammo_display(current_ammo, max_ammo)

func update_score(player_score: int, opponent_score: int):
	update_score_display(player_score, opponent_score)

func update_timer(time_remaining: float):
	update_timer_display(time_remaining)

# Internal update functions
func update_health_display(health: float, max_health: float, armor: float = 0.0):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		
		# Change color based on health percentage
		var health_percent = health / max_health
		if health_percent > 0.6:
			health_bar.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED
	
	if health_label:
		health_label.text = str(int(health)) + "/" + str(int(max_health))
	
	# Update armor bar
	if armor_bar:
		armor_bar.max_value = 100.0  # Assuming max armor is 100
		armor_bar.value = armor
		armor_bar.visible = armor > 0
	
	if armor_label:
		armor_label.text = str(int(armor))
		armor_label.visible = armor > 0

func update_ammo_display(current_ammo: int, max_ammo: int):
	if ammo_label:
		if max_ammo > 0:
			ammo_label.text = str(current_ammo) + "/" + str(max_ammo)
		else:
			ammo_label.text = "∞"  # Infinite ammo

func update_score_display(player_score: int, opponent_score: int):
	if score_label:
		score_label.text = str(player_score) + " - " + str(opponent_score)

func update_timer_display(time_remaining: float):
	if timer_label:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]
		
		# Change color when time is running low
		if time_remaining <= 60.0:  # Last minute
			timer_label.modulate = Color.RED
		elif time_remaining <= 180.0:  # Last 3 minutes
			timer_label.modulate = Color.YELLOW
		else:
			timer_label.modulate = Color.WHITE

# Crosshair functions
func set_crosshair_style(style: String):
	if crosshair and crosshair.has_method("set_style"):
		crosshair.set_style(style)

func show_crosshair_hit_feedback():
	if crosshair and crosshair.has_method("show_hit_feedback"):
		crosshair.show_hit_feedback()

# Kill feed functions
func add_kill_feed_entry(killer: String, victim: String, weapon: String):
	if kill_feed and kill_feed.has_method("add_entry"):
		kill_feed.add_entry(killer, victim, weapon)

# Utility functions
func show_spawn_protection_indicator():
	# TODO: Implement spawn protection indicator
	pass

func hide_spawn_protection_indicator():
	# TODO: Implement spawn protection indicator
	pass

func show_round_info(round_number: int, max_rounds: int):
	# TODO: Implement round info display
	pass 
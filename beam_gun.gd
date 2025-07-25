extends WeaponBase
class_name BeamGun

@export var beam_range: float = 15.0
@export var beam_effect_scene: PackedScene
@export var damage_tick_rate: float = 0.1  # How often to apply damage (seconds)
@export var damage_per_tick: float = 5.0   # Damage per tick

# Beam-specific properties
var persistent_beam: Node3D = null
var is_firing: bool = false
var damage_timer: float = 0.0

# Client prediction variables
var predicted_is_firing: bool = false
var last_input_shoot: bool = false

func initialize_from_config():
	weapon_id = "beam_gun"
	weapon_name = "Beam Gun"
	damage = 20.0
	fire_rate = 0.05  # Very fast firing
	ammo_capacity = 100

	weapon_range = beam_range
	
	# Mark as continuous weapon
	is_continuous_weapon = true
	
	# Create weapon model
	create_weapon_model()

func create_weapon_model():
	# Weapon model will be added manually in the scene
	# Just ensure Marker3D exists for muzzle point
	var muzzle_marker = get_node_or_null("Marker3D")
	if not muzzle_marker:
		print("WARNING: Please add a Marker3D node as child of BeamGun for muzzle point!")

func _process(delta):
	# Client prediction - update immediately on input
	if multiplayer.get_unique_id() == weapon_owner.player:
		handle_client_prediction(delta)
	
	# All clients update beam based on synced firing state
	var should_be_firing = false
	if weapon_owner.input:
		should_be_firing = weapon_owner.input.is_firing
	
	# Update firing state based on synchronized input
	if should_be_firing and not is_firing:
		perform_start_fire()
	elif not should_be_firing and is_firing:
		perform_stop_fire()
	
	# All clients update beam visuals based on synced state
	if is_firing:
		update_persistent_beam()
	else:
		clear_beam()

func _physics_process(delta):
	# Server authority - validate and apply damage
	if multiplayer.is_server():
		handle_server_authority(delta)

func handle_client_prediction(delta):
	# Get current shoot input
	var current_shoot_input = false
	if weapon_owner.input:
		current_shoot_input = weapon_owner.input.shoot_input
	
	# Check for input changes
	if current_shoot_input != last_input_shoot:
		last_input_shoot = current_shoot_input
		
		if current_shoot_input:
			# Update synchronized firing state
			if weapon_owner.input:
				weapon_owner.input.is_firing = true
		else:
			# Update synchronized firing state
			if weapon_owner.input:
				weapon_owner.input.is_firing = false
				weapon_owner.input.target_path = NodePath()  # Clear target when not firing
	
	# Client prediction - update immediately on input
	if multiplayer.get_unique_id() == weapon_owner.player:
		# Client does raycast for damage prediction based on shoot input
		if weapon_owner.camera and current_shoot_input:
			var camera = weapon_owner.camera
			var camera_pos = camera.global_position
			var direction = -camera.global_transform.basis.z
			
			var target_info = find_target_and_collision_point(camera_pos, direction)
			if target_info.target:
				print("[BEAMGUN] Client predicting damage to: ", target_info.target.name)
				# Set target path for server to validate
				weapon_owner.input.target_path = target_info.target.get_path()

func handle_server_authority(delta):
	# Server validates firing state and applies damage
	if is_firing and multiplayer.is_server():
		update_damage_ticks(delta)

func update_damage_ticks(delta):
	damage_timer += delta
	
	if damage_timer >= damage_tick_rate:
		damage_timer = 0.0
		apply_damage_from_synced_target()

func apply_damage_from_synced_target():
	# Server validates the synced target and applies damage
	if not weapon_owner.input or weapon_owner.input.target_path.is_empty():
		return
	
	var target = get_node_or_null(weapon_owner.input.target_path)
	if target and (target.is_in_group("World") or target.is_in_group("players")):
		# Quick server validation for security
		if weapon_owner.camera:
			var camera = weapon_owner.camera
			var camera_pos = camera.global_position
			var direction = -camera.global_transform.basis.z
			
			# Fast validation raycast
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(camera_pos, camera_pos + direction * weapon_range)
			query.exclude = [weapon_owner]
			
			var result = space_state.intersect_ray(query)
			if result and result.collider == target:
				print("[BEAMGUN] Server validation passed, applying damage to: ", target.name)
				apply_damage_to_target(target, damage_per_tick)
			else:
				print("[BEAMGUN] Server validation failed - target not in line of sight")
		else:
			print("[BEAMGUN] Server validation failed - no camera")
	else:
		print("[BEAMGUN] Server validation failed - invalid target")

func perform_start_fire():
	if is_firing:
		return
	
	print("Beam gun starting to fire!")
	is_firing = true
	damage_timer = 0.0
	
	# Create persistent beam
	create_persistent_beam()

func perform_stop_fire():
	if not is_firing:
		return
	
	print("Beam gun stopping fire!")
	is_firing = false
	
	# Destroy persistent beam
	destroy_persistent_beam()

func create_persistent_beam():
	if persistent_beam:
		destroy_persistent_beam()
	
	# Use the existing LineRenderer as child of beam gun
	var line_renderer = get_node_or_null("LineRenderer3D")
	if line_renderer:
		persistent_beam = line_renderer
		# Configure the line renderer
		persistent_beam.use_global_coords = true  # Use global coordinates for world space
		persistent_beam.visible = true

	else:
		print("ERROR: LineRenderer3D not found as child of beam gun!")

func clear_beam():
	if persistent_beam:
		persistent_beam.visible = false

func destroy_persistent_beam():
	if persistent_beam:
		# Clear the beam points instead of destroying the node
		clear_beam()
		persistent_beam = null

func update_persistent_beam():
	if not persistent_beam or not weapon_owner.camera:
		return

	# All clients calculate beam points when firing (for visibility)
	if is_firing:
		calculate_and_set_beam_points()
	
	# All clients use the synced beam points (in global coordinates)
	if weapon_owner.input:
		var start_point = weapon_owner.input.beam_start_point
		var end_point = weapon_owner.input.beam_end_point
		
		# Set the points in global space using a typed array
		var points_array: Array[Vector3] = [start_point, end_point]
		persistent_beam.points = points_array

func calculate_and_set_beam_points():
	if not weapon_owner.input:
		return
		
	# Calculate beam points based on camera and muzzle
	var camera = weapon_owner.camera
	var camera_pos = camera.global_position
	var direction = -camera.global_transform.basis.z
	
	# Only the weapon owner does the raycast for visual beam points
	var target = null
	var collision_point = null
	if multiplayer.get_unique_id() == weapon_owner.player:
		var target_info = find_target_for_visuals(camera_pos, direction)
		target = target_info.target
		collision_point = target_info.collision_point

	# Find the Marker3D anywhere under BeamGun
	var muzzle_marker = find_child("Marker3D", true, false)
	var start_point = muzzle_marker.global_position if muzzle_marker else global_position

	# Determine the end point (raycast hit or max range)
	var end_point = start_point + direction * weapon_range
	if target and collision_point:
		end_point = collision_point

	# Set the synced beam points
	weapon_owner.input.beam_start_point = start_point
	weapon_owner.input.beam_end_point = end_point

func find_target_for_visuals(from: Vector3, direction: Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * weapon_range)
	query.exclude = [weapon_owner]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		var collision_point = result.position
		
		# Always hit things in World or players layers for visuals
		if collider.is_in_group("World") or collider.is_in_group("players"):
			return {"target": collider, "collision_point": collision_point}
	
	return {"target": null, "collision_point": null}

func find_target_in_direction(from: Vector3, direction: Vector3) -> Node3D:
	var target_info = find_target_and_collision_point(from, direction)
	return target_info.target

func find_target_and_collision_point(from: Vector3, direction: Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * weapon_range)
	query.exclude = [weapon_owner]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		var collision_point = result.position
		
		print("[BEAMGUN] Raycast hit: ", collider.name, " Groups: ", collider.get_groups())
		
		# Always hit things in World or players layers
		if collider.is_in_group("World") or collider.is_in_group("players"):
			print("[BEAMGUN] Valid target found: ", collider.name)
			
			# Search for health component and apply damage (server only)
			if multiplayer.is_server():
				print("[BEAMGUN] Server applying damage to: ", collider.name)
				apply_damage_to_target(collider, damage_per_tick)
			else:
				print("[BEAMGUN] Not server, skipping damage application")
			
			return {"target": collider, "collision_point": collision_point}
		else:
			print("[BEAMGUN] Invalid target: ", collider.name, " - Not in World or players group")
	else:
		print("[BEAMGUN] No raycast hit found")
	
	return {"target": null, "collision_point": null}

func apply_damage_to_target(target: Node, damage: float):
	# Search for health component in the target or its children
	var health_component = find_health_component(target)
	if health_component:
		print("[BEAMGUN] take_damage: target=", target.name, " health_component=", health_component.name, " amount=", damage, " source=", weapon_owner)
		health_component.take_damage(damage, weapon_owner)
		apply_vampirism(damage)
	else:
		print("[BEAMGUN] No health component found on: ", target.name)

func find_health_component(node: Node) -> Health:
	print("[BEAMGUN] Searching for Health component in: ", node.name, " Type: ", node.get_class())
	
	# Check if the node itself has a Health component
	if node is Health:
		print("[BEAMGUN] Found Health component directly on: ", node.name)
		return node
	
	# Search children for Health component
	for child in node.get_children():
		print("[BEAMGUN] Checking child: ", child.name, " Type: ", child.get_class())
		if child is Health:
			print("[BEAMGUN] Found Health component on child: ", child.name)
			return child
		# Recursively search deeper
		var found = find_health_component(child)
		if found:
			print("[BEAMGUN] Found Health component in deeper child: ", found.name)
			return found
	
	print("[BEAMGUN] No Health component found in: ", node.name)
	return null

func spawn_beam_effect(from: Vector3, to: Vector3):
	# This is now handled by the persistent beam
	# Keep for compatibility but it's not used
	pass 

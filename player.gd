extends CharacterBody3D

# Movement configuration (matching Rust MovementConfig)
const SPEED = 7.0  # Maximum player speed (matches Rust default)
const JUMP_VELOCITY = 5.0  # Upward velocity applied when jumping (matches Rust default)
const STEP_HEIGHT = 0.55  # Maximum step height (matches Rust MAX_STEP_HEIGHT)
const GROUND_CHECK_OFFSET = 0.01  # Small offset for ground snapping

# Quake-like movement parameters (matching Rust defaults)
const GROUND_ACCELERATE = 10.0  # Acceleration when on ground (units/sec^2)
const AIR_ACCELERATE = 1.0  # Acceleration when in air (units/sec^2)

const FRICTION = 6.0  # Friction applied when on ground

# Movement input handling
@export var use_analog_input: bool = false  # Enable analog input support (gamepad) vs digital (WASD)

# Step climbing parameters (matching Rust MovementConfig)
const STEP_CLIMB_SPEED = 1.5  # Maximum speed for climbing steps (matches Rust step_climb_speed)
const MIN_STEP_SPEED = 1.0  # Minimum speed for step climbing (matches Rust min_step_speed)

# Ground check configuration - configurable in editor
@export_group("Ground Check Shape")
@export_range(0.01, 0.5, 0.01) var ground_check_radius: float = 0.05  # Radius of ground check cylinder (script control)
@export_range(0.01, 0.2, 0.01) var ground_check_height: float = 0.02  # Height of ground check cylinder (script control)
@export var use_editor_shape_cast: bool = true  # Use ShapeCast3D's editor-set position, target_position, and shape

@export_group("Ground Detection Behavior")
@export_range(0.1, 2.0, 0.01) var normalization_distance: float = 1.3  # Distance to normalize to (replaces STEP_HEIGHT for ground detection)
@export_range(0.01, 0.2, 0.01) var jump_grace_period: float = 0.05  # Time after jump to skip ground detection
@export_range(0.001, 0.1, 0.001) var landing_threshold: float = 0.015  # Base threshold for landing detection
@export_range(0.01, 0.2, 0.01) var air_time_threshold: float = 0.05  # Minimum air time before ground detection
@export_range(0.001, 0.1, 0.001) var close_ground_threshold: float = 0.01  # Threshold for "close enough to ground"

@export_group("Step Climbing")
@export_range(0.5, 3.0, 0.1) var step_climb_speed: float = 1.5  # Speed for climbing steps
@export_range(0.1, 2.0, 0.1) var min_step_speed: float = 1.0  # Minimum step climbing speed
@export_range(0.00, 0.5, 0.01) var step_speed_multiplier: float = 0.3  # Multiplier for step speed calculation (matches Rust default)

@export_group("Debug")
@export var show_ground_check_debug: bool = true  # Show ground check debug visualization

# Will be set dynamically from the collider
var capsule_radius: float = 0.5
var capsule_height: float = 2.0

# Ground detection constants (will be set dynamically from ShapeCast3D)
var ground_cast_radius: float = 0.0
var ground_cast_half_height: float = 0.01

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Set by the authority, synchronized on spawn.
@export var player := 1 :
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		$PlayerInput.set_multiplayer_authority(id)

# Player synchronized input.
@onready var input = $PlayerInput
@onready var ground_check = $GroundCheck

# Custom ground state tracking
var is_grounded_custom = false
var was_grounded_last_frame = false

# Jump and fall timers (matching Rust implementation)
var just_jumped_timer: float = 999.0  # Seconds since last jump (starts high to prevent immediate jumping)
var fall_timer: float = 0.0  # Seconds spent falling
var previous_fall_timer: float = 0.0  # Previous frame's fall timer value

# Quake-like movement components (matching Rust implementation)
var sticky_wish_dir: Vector3 = Vector3.ZERO  # Sticky wish direction for air control

	# Mouse look variables
var mouse_sensitivity: float = 0.002  # Mouse sensitivity
var spring_arm: SpringArm3D  # Spring arm for camera collision
var camera_pivot: Node3D  # Camera pivot for vertical rotation
var camera: Camera3D  # The actual camera
const MIN_PITCH: float = -1.2  # Minimum pitch (looking down)
const MAX_PITCH: float = 1.2   # Maximum pitch (looking up)

# Player manager
var player_manager: PlayerManager

func _ready():
	# Set up camera system
	setup_camera()
	
	# Set up player manager
	setup_player_manager()
	
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		camera.current = true
		# Capture mouse for first-person view
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Only process on server.
	# EDIT: Left the client simulate player movement too to compesate network latency.
	# set_physics_process(multiplayer.is_server())
	
	# Get actual collider dimensions
	get_collider_dimensions()
	
	# Position the ground check ShapeCast3D correctly
	position_ground_check()


func _physics_process(delta):
	# Update jump and fall timers (matching Rust implementation)
	update_jump_and_fall_timers(delta)
	
	# Apply gravity only when not grounded
	if not is_grounded_custom:
		velocity.y -= gravity * delta
	else:
		# When grounded, ensure no downward velocity
		if velocity.y < 0:
			velocity.y = 0

	# Handle Jump (matching Rust implementation exactly)
	if input.jumping and is_grounded_custom:  # No timer check - allows bunny hopping!
		velocity.y = JUMP_VELOCITY
		just_jumped_timer = 0.0  # Reset jump timer (matching Rust logic)
		is_grounded_custom = false  # Immediately become ungrounded when jumping
		# Note: Don't reset input.jumping here - let the input system handle it for network sync

	# Handle Quake-like movement (matching Rust implementation)
	perform_quake_movement(delta)

	# Custom ground check and step normalization BEFORE movement
	perform_custom_ground_check_and_step_normalization()
	
	# Use move_and_slide for proper wall sliding while preserving our custom physics
	move_and_slide()
	
	# Update our custom grounded state based on move_and_slide results
	# This ensures compatibility with our custom ground detection
	if is_on_floor():
		is_grounded_custom = true
		# Zero out downward velocity when grounded (matching our custom logic)
		if velocity.y < 0:
			velocity.y = 0
	
	# Apply synchronized rotations for all players
	apply_synchronized_rotations()
	
	# Weapon input is now handled by the weapon itself for client prediction
	# The weapon system handles its own firing logic
	
	# Toggle infinite ammo with F1 key (for testing)
	if Input.is_action_just_pressed("ui_focus_next"):  # F1 key
		if player_manager and player_manager.get_weapon_system() and player_manager.get_weapon_system().current_weapon:
			player_manager.get_weapon_system().current_weapon.toggle_infinite_ammo()


func perform_custom_ground_check_and_step_normalization():
	# Use jump timer to determine if we should skip ground logic (matching Rust)
	var just_jumped_active = just_jumped_timer < jump_grace_period  # Increased threshold for proper jump grace period
	
	# Skip ground detection if we just jumped (matching Rust logic)
	if just_jumped_active:
		is_grounded_custom = false
		return
	
	# Force update the shape cast to get current collision info
	ground_check.force_update_transform()
	
	# Check if the shape cast is colliding
	if ground_check.is_colliding():
		var collision_point = ground_check.get_collision_point(0)  # Get first collision
		var collision_normal = ground_check.get_collision_normal(0)  # Get first collision normal
		
		# Calculate distance from cast start point (matching Rust logic)
		# Use the actual ShapeCast3D position and collision point
		var cast_start_y = global_position.y + ground_check.position.y
		var distance_to_ground = cast_start_y - collision_point.y
		
		# Store ground cast distance (matching Rust logic)
		var ground_cast_distance = distance_to_ground
		
		# Calculate the difference from STEP_HEIGHT (matching Rust logic exactly)
		var diff = normalization_distance - distance_to_ground
		var air_time = fall_timer
		
		# Landing thresholds (matching Rust logic)
		var base_landing_threshold = landing_threshold
		var dynamic_landing_threshold = abs(velocity.y) * get_physics_process_delta_time() + base_landing_threshold
		
		# Ground detection logic (matching Rust logic exactly)
		if distance_to_ground <= normalization_distance and air_time > air_time_threshold:
			# Snap player so ground cast distance is exactly STEP_HEIGHT (matching Rust logic exactly)
			var correction = distance_to_ground - normalization_distance
			global_position.y -= correction  # Move down by the correction amount
			velocity.y = 0.0
			is_grounded_custom = true
		elif air_time <= 0.01 and abs(diff) > close_ground_threshold:
			# Only allow step smoothing if not falling (matching Rust logic exactly)
			var horizontal_speed = Vector2(velocity.x, velocity.z).length()
			var calculated_step_speed = step_climb_speed + (horizontal_speed * horizontal_speed * step_speed_multiplier)
			var dynamic_step_speed = max(calculated_step_speed, min_step_speed)
			var max_step_delta = dynamic_step_speed * get_physics_process_delta_time()
			var movement_to_apply = 0.0
			
			if diff > 0.0:
				movement_to_apply = min(diff, max_step_delta)  # Limit upward movement
			else:
				movement_to_apply = max(diff, -max_step_delta)  # Limit downward movement
			
			velocity.y = movement_to_apply / get_physics_process_delta_time()
			# Note: Rust does NOT set grounded.0 = true here, so we don't either
		elif abs(diff) <= close_ground_threshold:
			# Close enough to ground (matching Rust logic exactly)
			velocity.y = 0.0
			is_grounded_custom = true
		# Note: Rust has no else case here, so we don't either
	else:
		# No ground detected (matching Rust logic exactly)
		# If no ground hit, grounded should be true if ground_cast_distance is Some and <= STEP_HEIGHT
		# Since we don't have persistent ground_cast_distance storage, we set to false
		is_grounded_custom = false
	
	# Update grounded state for next frame
	was_grounded_last_frame = is_grounded_custom


# Get the actual collider dimensions from the CharacterBody3D
func get_collider_dimensions():
	var collider = get_node_or_null("CollisionShape3D")
	if collider and collider.shape:
		if collider.shape is CapsuleShape3D:
			var capsule_shape = collider.shape as CapsuleShape3D
			capsule_radius = capsule_shape.radius
			capsule_height = capsule_shape.height
		elif collider.shape is CylinderShape3D:
			var cylinder_shape = collider.shape as CylinderShape3D
			capsule_radius = cylinder_shape.radius
			capsule_height = cylinder_shape.height
		else:
			pass # Unknown collider shape type, using default values
	
	# Get ground cast dimensions from the actual ShapeCast3D shape
	get_ground_cast_dimensions()


# Get ground cast dimensions from configurable values
func get_ground_cast_dimensions():
	# This function is now handled by update_ground_check_shape()
	# It's kept for compatibility but the actual logic is in update_ground_check_shape()
	pass


# Perform Quake-like movement (matching Rust implementation)
func perform_quake_movement(delta: float):
	# Calculate wish direction and speed (matching Rust logic)
	var wish_vel = Vector3(input.direction.x, 0, input.direction.y).normalized()  # Fixed: removed negative sign
	# Use synchronized yaw rotation for consistent movement direction across network
	var wish_dir = (Basis(Vector3.UP, input.yaw_rotation) * wish_vel).normalized()
	
	# Fix diagonal movement speed - handle digital vs analog input
	var input_magnitude = input.direction.length()
	var wish_speed: float
	
	if use_analog_input:
		# Analog input (gamepad) - speed varies with input magnitude
		wish_speed = min(input_magnitude * SPEED, SPEED)
	else:
		# Digital input (WASD) - consistent speed in all directions
		wish_speed = SPEED
	
	# Sticky wish_dir logic (matching Rust)
	if wish_dir.length_squared() > 0.001:
		sticky_wish_dir = wish_dir
	
	# Debug: Print movement values
	if input.direction.length() > 0:
		print("Wish vel: ", wish_vel, " Wish dir: ", wish_dir, " Wish speed: ", wish_speed, " Input mag: ", input_magnitude)
		print("Current vel: ", Vector3(velocity.x, 0, velocity.z), " Speed: ", Vector3(velocity.x, 0, velocity.z).length())
	
	# Apply friction and acceleration based on grounded state
	if is_grounded_custom:
		apply_friction(delta)
		accelerate(wish_dir, wish_speed, GROUND_ACCELERATE, delta)
	else:
		# Air movement (matching Rust implementation exactly)
		accelerate(wish_dir, wish_speed, AIR_ACCELERATE, delta)


# Apply friction to velocity when grounded (matching Rust implementation)
func apply_friction(delta: float):
	var speed = Vector2(velocity.x, velocity.z).length()
	if speed <= 0.0:
		return
	
	var drop = speed * FRICTION * delta
	var new_speed = max(speed - drop, 0.0)
	
	if speed > 0.0:
		var speed_ratio = new_speed / speed
		velocity.x *= speed_ratio
		velocity.z *= speed_ratio


# Accelerate velocity in wish direction (matching Rust implementation)
func accelerate(wish_dir: Vector3, wish_speed: float, accel: float, delta: float):
	var current_speed = Vector3(velocity.x, 0, velocity.z).dot(wish_dir)
	var add_speed = wish_speed - current_speed
	
	if add_speed <= 0.0:
		return
	
	var accel_speed = accel * wish_speed * delta
	accel_speed = min(accel_speed, add_speed)
	
	velocity.x += accel_speed * wish_dir.x
	velocity.z += accel_speed * wish_dir.z





# Update jump and fall timers (matching Rust implementation)
func update_jump_and_fall_timers(delta: float):
	# Update just jumped timer (matching Rust logic)
	if just_jumped_timer < 999.0:  # Don't overflow
		just_jumped_timer += delta
	
	# Update fall timer (matching Rust logic)
	if is_grounded_custom:
		fall_timer = 0.0
	else:
		fall_timer += delta
	
	# Update previous fall timer (matching Rust logic)
	previous_fall_timer = fall_timer


# Position the ground check ShapeCast3D using configurable values
func position_ground_check():
	if ground_check:
		if use_editor_shape_cast:
			# Use the ShapeCast3D's editor-set position and target_position
			# Don't override them - let the editor control them
			print("Using editor-set ShapeCast3D position: ", ground_check.position)
			print("Using editor-set ShapeCast3D target: ", ground_check.target_position)
		else:
			# Use script-controlled positioning (legacy mode)
			ground_check.position = Vector3(0, GROUND_CHECK_OFFSET, 0)
			ground_check.target_position = Vector3(0, -normalization_distance * 2.0, 0)
		
		# Update the ground check shape with configurable dimensions
		update_ground_check_shape()
		
		print("Ground check radius: ", ground_check_radius, " height: ", ground_check_height)

# Update the ground check shape with configurable dimensions
func update_ground_check_shape():
	if ground_check:
		if use_editor_shape_cast:
			# Use the ShapeCast3D's editor-set shape
			if ground_check.shape:
				if ground_check.shape is CylinderShape3D:
					var cylinder = ground_check.shape as CylinderShape3D
					ground_cast_radius = cylinder.radius
					ground_cast_half_height = cylinder.height * 0.5
				elif ground_check.shape is CapsuleShape3D:
					var capsule = ground_check.shape as CapsuleShape3D
					ground_cast_radius = capsule.radius
					ground_cast_half_height = capsule.height * 0.5
				else:
					# Fallback to script values for unknown shapes
					ground_cast_radius = ground_check_radius
					ground_cast_half_height = ground_check_height * 0.5
			else:
				# No shape set, use script values
				ground_cast_radius = ground_check_radius
				ground_cast_half_height = ground_check_height * 0.5
		else:
			# Script control: Create a new cylinder shape with configurable dimensions
			var new_shape = CylinderShape3D.new()
			new_shape.radius = ground_check_radius
			new_shape.height = ground_check_height
			
			# Apply the new shape to the ground check
			ground_check.shape = new_shape
			
			# Update the cached dimensions
			ground_cast_radius = ground_check_radius
			ground_cast_half_height = ground_check_height * 0.5
		
		# Update debug visualization
		ground_check.debug_shape_custom_color = Color(0, 0, 1, 1) if show_ground_check_debug else Color(0, 0, 0, 0)

# Handle property changes in the editor
func _set(property, value):
	# Update the ground check when properties change
	if property in ["ground_check_radius", "ground_check_height", "show_ground_check_debug", "use_editor_shape_cast"]:
		if ground_check:
			update_ground_check_shape()
		return true
	return false

# Optional: Add a getter for external scripts to check custom grounded state
func is_grounded() -> bool:
	return is_grounded_custom


# Optional: Add a getter for external scripts to check if player just landed
func just_landed() -> bool:
	return is_grounded_custom and not was_grounded_last_frame

# Apply synchronized rotations for all players (local and remote)
func apply_synchronized_rotations():
	# Apply horizontal rotation (yaw) to character
	rotation.y = input.yaw_rotation
	
	# Apply vertical rotation (pitch) to camera pivot
	if has_node("SpringArm3D/CameraPivot"):
		var camera_pivot = get_node("SpringArm3D/CameraPivot")
		camera_pivot.rotation.x = input.pitch_rotation

# Note: move_and_slide() automatically handles wall sliding
# Custom wall sliding is only needed when using move_and_collide()

# ALTERNATIVE IMPLEMENTATION: Custom sliding with move_and_collide
# Uncomment this function and replace move_and_slide() with perform_custom_sliding()
# if you want more control over the sliding behavior
func perform_custom_sliding(delta: float):
	const MAX_SLIDES = 4
	const EPSILON = 0.001
	
	var remaining_velocity = velocity * delta
	var slides = 0
	
	while remaining_velocity.length() > EPSILON and slides < MAX_SLIDES:
		var collision = move_and_collide(remaining_velocity)
		
		if collision:
			# Get collision normal and project velocity
			var normal = collision.get_normal()
			var velocity_3d = Vector3(velocity.x, 0, velocity.z)
			
			# Project velocity onto collision plane (Quake-style sliding)
			var projected_velocity = velocity_3d - normal * velocity_3d.dot(normal)
			
			# Preserve speed
			var current_speed = velocity_3d.length()
			if projected_velocity.length() > EPSILON:
				projected_velocity = projected_velocity.normalized() * current_speed
				velocity.x = projected_velocity.x
				velocity.z = projected_velocity.z
				remaining_velocity = projected_velocity * delta
			else:
				# No valid slide direction, stop
				remaining_velocity = Vector3.ZERO
			
			slides += 1
		else:
			# No collision, move freely
			break

# Player movement system - handles only movement and physics

# Set up camera system
func setup_camera():
	# Get references to existing nodes
	spring_arm = $SpringArm3D
	camera_pivot = $SpringArm3D/CameraPivot
	camera = $SpringArm3D/CameraPivot/Camera3D

# Set up player manager
func setup_player_manager():
	# Create player manager
	player_manager = PlayerManager.new()
	add_child(player_manager)

# Handle mouse input for camera rotation
func _input(event):
	# Only handle mouse input for the local player
	if player != multiplayer.get_unique_id():
		return
	
	# Handle mouse motion for camera rotation (only for local player)
	if event is InputEventMouseMotion and player == multiplayer.get_unique_id():
		# Horizontal rotation (yaw) - rotates the character
		input.yaw_rotation -= event.relative.x * mouse_sensitivity
		
		# Vertical rotation (pitch) - rotates the camera pivot
		input.pitch_rotation -= event.relative.y * mouse_sensitivity
		input.pitch_rotation = clamp(input.pitch_rotation, MIN_PITCH, MAX_PITCH)
		
		# Apply rotations (these will be synced for all players)
		apply_synchronized_rotations()
	
	# Handle escape key to toggle mouse capture
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset_movement_state():
	velocity = Vector3.ZERO
	is_grounded_custom = false
	was_grounded_last_frame = false
	just_jumped_timer = 999.0
	fall_timer = 0.0
	previous_fall_timer = 0.0
	sticky_wish_dir = Vector3.ZERO
	

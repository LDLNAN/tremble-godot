# COPYRIGHT Colormatic Studios
# MIT licence
# Quality Godot First Person Controller v2


extends CharacterBody3D

# TODO: Add descriptions for each value

@onready var rigid_body_3d = $RigidBody3D
@onready var collider = $Collider

@export_category("Character")
@export var base_speed : float = 2.25
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0
@export var slide_speed : float = 200.0

@export var slide_stop_speed : float = -.5
@export var slide_acceleration : float = 2.0
@export var grapple_acceleration : float = 2.0

@export var mouse_sensitivity : float = 0.1
@export var immobile : bool = false

var move_input : Vector2 = Vector2.ZERO

class MovementSettings:
	var max_speed : float = 0.0
	var acceleration : float = 0.0
	var deceleration : float = 0.0
	
	func _init(_max_speed, _acceleration, _deceleration):
		max_speed = _max_speed
		acceleration = _acceleration
		deceleration = _deceleration

var GROUND_SETTINGS : MovementSettings = MovementSettings.new(7.0, 14.0, 4.5)
var AIR_SETTINGS : MovementSettings = MovementSettings.new(7, 0.4, 2)
var STRAFE_SETTINGS : MovementSettings = MovementSettings.new(0.7, 60.0, 60.0)

var JUMP_FORCE : float = 5.5
var AIR_CONTROL : float = 0.3
var AUTO_JUMP : bool = true
var jump_queued : bool = false
var is_on_slope : bool = false
var dir : Vector3 = Vector3.ZERO
var vel : Vector3 = Vector3.ZERO
var dir_norm : Vector3 = Vector3.ZERO
@onready var jump_noise: FmodEventEmitter3D = $JumpNoise
@onready var step_noise: FmodEventEmitter3D = $StepNoise
@onready var hurt_noise: FmodEventEmitter3D = $HurtNoise
var animation_pause : bool = false
var friction : float = 0.0

var health : float = 100.0
@export var max_health : float = 100.0
var armor : float = 0.0
@export var max_armor : float = 50.0
@export_file var default_reticle

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var WEAPONBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer
@export var COLLISION_MESH : CollisionShape3D
@export_group("Controls")
# We are using UI controls because they are built into Godot Engine so they can be used right away
@export var JUMP : String = "jump"
@export var LEFT : String = "left"
@export var RIGHT : String = "right"
@export var FORWARD : String = "forward"
@export var BACKWARD : String = "backward"
@export var PAUSE : String = "ui_cancel"
@export var CROUCH : String = "crouch"
@export var SPRINT : String = "sprint"
@onready var ground_ray = $"ShapeCast3D"

# Uncomment if you want full controller support
#@export var LOOK_LEFT : String
#@export var LOOK_RIGHT : String
#@export var LOOK_UP : String
#@export var LOOK_DOWN : String

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = false
@export var crouch_enabled : bool = true
@export var slide_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true
@export var jump_animation : bool = true
@export var pausing_enabled : bool = true
@export var gravity_enabled : bool = true
var grapple
@onready var weapons = $Head/Weapons

# Member variables
var speed : float = base_speed
var current_speed : float = 0.0
var direction = Vector3.ZERO
var input_dir = Vector2.ZERO
# States: normal, crouching, sprinting, sliding
var state : String = "normal"
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.
var was_on_floor : bool = true # Was the player on the floor last frame (for landing animation)
var physics_position : Vector3 = Vector3.ZERO
var prev_physics_position : Vector3 = Vector3.ZERO
var ladder_normal : Vector3 = Vector3.UP

var FRICTION : float = 6.0
var GRAVITY : float = 17.5
# The reticle should always have a Control node as the root
var RETICLE : Control

# UI STUFF
@onready var vitals: MarginContainer = $UserInterface/Vitals

# BUFFS
var berserk : bool = false
var damage_multiplier : float = 1.0

var resistance : bool = false
var resistance_multiplier : float = 1.0

var haste : bool = false
var haste_multiplier : float = 1.0

func buff(type: int):
	match type:
		1:
			start_berserk()
		2:
			start_resistance()
		3:
			start_haste()

func start_berserk():
	berserk = true
	damage_multiplier = 2.0
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 20
	timer.connect("timeout", Callable(self, "disable_berserk"))
	timer.start()

func disable_berserk():
	damage_multiplier = 1.0
	berserk = false

func start_resistance():
	resistance_multiplier = 0.5
	resistance = true
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 20
	timer.connect("timeout", Callable(self, "disable_resistance"))
	timer.start()

func disable_resistance():
	resistance_multiplier = 1.0
	resistance = false

func start_haste():
	haste_multiplier = 1.5
	haste = true
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 20
	timer.connect("timeout", Callable(self, "disable_haste"))
	timer.start()

func disable_haste():
	haste_multiplier = 1.0
	haste = false


func heal(amount : float):
	health += amount
	if health > max_health:
		health = max_health
	vitals.update_health(health, max_health)
	

func armor_up(amount : float):
	armor += amount
	if armor > max_armor:
		armor = max_armor
	vitals.update_armor(armor, max_armor)

func damage(amount : float):
	if armor > 0:
		armor -= amount * resistance_multiplier
		if armor < 0:
			health += armor
			armor = 0
		# add armor break animation here
	else:
		health -= amount * resistance_multiplier
		# add flinch animation here
		if health <= 0:
			die() 
	hurt_noise["event_parameter/health/value"] = health
	hurt_noise.play()
	vitals.update_armor(armor, max_armor)
	vitals.update_health(health, max_health)

func die():
	
	# add death animation here
	pass



func _ready():
	physics_position = global_transform.origin
	prev_physics_position = physics_position
	damage_multiplier = 1.0
	health = max_health
	armor = max_armor
	vitals.update_armor(armor, max_armor)
	vitals.update_health(health, max_health)

	#It is safe to comment this line if your game doesn't start with the mouse captured
	state = "normal"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	grapple = get_node("Head/Offhand/Grapple")
	# If the controller is rotated in a certain direction for game design purposes, redirect this rotation into the head.
	HEAD.rotation.y = rotation.y
	rotation.y = 0
	
	if default_reticle:
		change_reticle(default_reticle)
	
	# Reset the camera position
	# If you want to change the default head height, change these animations.
	HEADBOB_ANIMATION.play("RESET")
	JUMP_ANIMATION.play("RESET")
	CROUCH_ANIMATION.play("RESET")
	
	check_controls()

func check_controls(): # If you add a control, you might want to add a check for it here.
	if !InputMap.has_action(JUMP):
		push_error("No control mapped for jumping. Please add an input map control. Disabling jump.")
		jumping_enabled = false
	if !InputMap.has_action(LEFT):
		push_error("No control mapped for move left. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(RIGHT):
		push_error("No control mapped for move right. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(FORWARD):
		push_error("No control mapped for move forward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(BACKWARD):
		push_error("No control mapped for move backward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(PAUSE):
		push_error("No control mapped for move pause. Please add an input map control. Disabling pausing.")
		pausing_enabled = false
	if !InputMap.has_action(CROUCH):
		push_error("No control mapped for crouch. Please add an input map control. Disabling crouching.")
		crouch_enabled = false
	if !InputMap.has_action(SPRINT):
		push_error("No control mapped for sprint. Please add an input map control. Disabling sprinting.")
		sprint_enabled = false


func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()
	
	RETICLE = load(reticle).instantiate()
	RETICLE.character = self
	$UserInterface.add_child(RETICLE)

func air_move(delta : float) -> void:
	var accel : float = 0.0
	var wishdir : Vector3 = Vector3(dir.x, 0.0, dir.z)
	var wishspeed : float = wishdir.length()
	wishspeed *= AIR_SETTINGS.max_speed * haste_multiplier
	dir_norm = wishdir.normalized()
	# CPM air control
	var wishspeed2 : float = wishspeed
	if vel.dot(wishdir) < 0.0:
		accel = AIR_SETTINGS.deceleration
	else:
		accel = AIR_SETTINGS.acceleration
	if move_input.x == 0.0 and move_input.y != 0.0:
		print("Strafing")
		if wishspeed > STRAFE_SETTINGS.max_speed:
			wishspeed = STRAFE_SETTINGS.max_speed
		accel = STRAFE_SETTINGS.acceleration
	accelerate(dir_norm, wishspeed, accel, delta)
	if AIR_CONTROL > 0:
		air_control(dir_norm, wishspeed2, delta)
	# Apply gravity
	vel.y -= GRAVITY * delta

func air_control(target_dir : Vector3, target_speed : float, delta : float) -> void:
	var dot        : float
	var speed      : float
	var original_y : float
	
	if move_input.y == 0.0: 
		return
	
	original_y = vel[1]
	vel[1] = 0.0
	speed = vel.length()
	vel = vel.normalized()
	
	# Change direction while slowing down
	dot = vel.dot(target_dir)
	if dot > 0.0 :
		var k = 32.0 * AIR_CONTROL * dot * dot * delta
		vel[0] = vel[0] * speed + target_dir[0] * k
		vel[1] = vel[1] * speed + target_dir[1] * k
		vel[2] = vel[2] * speed + target_dir[2] * k
		vel = vel.normalized()
	
	vel[0] *= speed
	vel[1] = original_y
	vel[2] *= speed


func process_movement(delta):
	# Setting the direction
	dir = move_input.x * $Head.global_transform.basis.z
	dir += move_input.y * $Head.global_transform.basis.x
	queue_jump()
	if is_on_floor() && !state == "sliding":
		ground_move(delta)
	else:
		air_move(delta)
	if state == "grappling":
		velocity.x = lerp(velocity.x, dir.x * speed + grapple.desired_velocity.x, grapple_acceleration * delta)
		velocity.z = lerp(velocity.z, dir.z * speed + grapple.desired_velocity.z, grapple_acceleration * delta)
		velocity.y = grapple.desired_velocity.y
	elif state == "sliding":
		var key_direction = Vector3(dir.x, 0, dir.z).normalized()
		var direction
		var speed
		if key_direction.length() > 0.1:

			var current_speed = Vector2(rigid_body_3d.linear_velocity.x, rigid_body_3d.linear_velocity.z).length()
			var current_direction = Vector3(rigid_body_3d.linear_velocity.x, 0, rigid_body_3d.linear_velocity.z).normalized()

			var new_direction = Vector3(dir.x, 0, dir.z).normalized()
			var smooth_direction = current_direction.slerp(new_direction, delta)
			rigid_body_3d.linear_velocity.x = smooth_direction.x * current_speed
			rigid_body_3d.linear_velocity.z = smooth_direction.z * current_speed
		#rigid_body_3d.rotation.x = lerp(rigid_body_3d.rotation.x, direction.x * 15, (slide_acceleration / 2) * delta)
		#rigid_body_3d.linear_velocity.z = lerp(rigid_body_3d.linear_velocity.z, direction.z * 15, (slide_acceleration / 2) * delta)

func _physics_process(delta):
	process_movement(delta)
	move_and_slide()


	# The player is not able to stand up if the ceiling is too low
	low_ceiling = $CrouchCeilingDetection.is_colliding()
	
	if dynamic_fov: # This may be changed to an AnimationPlayer
		update_camera_fov()
	
	if view_bobbing && !animation_pause:
		headbob_animation()
	
	if JUMP_ANIMATION:
		if !was_on_floor and is_on_floor(): # The player just landed
			JUMP_ANIMATION.play("land_left", 1)
			step_noise.play()
			
	if state == "grappling":
		input_dir.y = 0
	var velocityxz = Vector2(velocity.x, velocity.z)
	if rigid_body_3d.linear_velocity.length() <= slide_stop_speed and state == "sliding":
		if Input.is_action_pressed(CROUCH):
			enter_crouch_state()
		else:
			enter_normal_state()
	
	was_on_floor = is_on_floor() # This must always be at the end of physics_process
	prev_physics_position = physics_position
	physics_position = global_transform.origin

func check_floor() -> bool:
	move_and_slide()
	return is_on_floor()

func enter_in_air_state():
	print("entering in_air state")
	var prev_state = state
	state = "in_air"
	# Keep current speed when entering air state to preserve momentum
	if prev_state == "sprinting":
		# Maintain sprint momentum in the air
		speed = sprint_speed
	else:
		# For bunny hopping, maintain the current speed to preserve momentum
		# Don't reset to base_speed as it breaks bunny hopping momentum
		pass

# Define a constant for minimum slide velocity
const MIN_SLIDE_VELOCITY = 8
const AIR_CROUCH_STATE = "air_crouching"  # New state for air crouching

func handle_state(moving):
	# Cache floor and ceiling checks to avoid multiple calls
	var on_floor = is_on_floor()
	var ceiling_blocked = $CrouchCeilingDetection.is_colliding()
	var horizontal_velocity = Vector2(velocity.x, velocity.z).length()
	var is_bunny_hopping = continuous_jumping and Input.is_action_pressed(JUMP)
	var moving_forward = Input.is_action_pressed("forward")
	var crouching_pressed = Input.is_action_pressed(CROUCH)
	
	# Handle transitions between floor and air states
	if !on_floor:
		if state != "sliding" and state != "grappling" and state != "in_air" and state != AIR_CROUCH_STATE:
			enter_in_air_state()
		
		# Handle air crouching state specifically
		if state == "in_air" and crouching_pressed:
			state = AIR_CROUCH_STATE
			CROUCH_ANIMATION.play("crouch_air", 0.2)
		elif state == AIR_CROUCH_STATE and !crouching_pressed:
			state = "in_air"
			CROUCH_ANIMATION.play_backwards("crouch_air", 0.2)
		
		return  # Exit early to avoid conflicting state changes when in air
		
	# Landing handling
	if (state == "in_air" or state == AIR_CROUCH_STATE) and on_floor:
		if crouching_pressed and (horizontal_velocity > MIN_SLIDE_VELOCITY or Input.is_action_pressed(SPRINT)):
			enter_sliding_state()
		elif crouching_pressed:
			enter_crouch_state()
		elif is_bunny_hopping:
			# If bunny hopping, don't change state on landing briefly
			# Just preserve in_air state to maintain momentum for next jump
			jump_queued = true
		else:
			enter_normal_state()
	
	# Handle sprint state
	if sprint_enabled and state != "sliding" and state != "grappling" and state != "in_air" and state != "crouching":
		# Don't enter sprint state if bunny hopping (holding jump with continuous jumping enabled)
		if !is_bunny_hopping:
			if sprint_mode == 0:  # Hold to sprint
				if Input.is_action_pressed(SPRINT) and moving_forward:
					if moving and state != "sprinting":
						enter_sprint_state()
					elif !moving_forward and state == "sprinting":
						enter_normal_state()
				elif state == "sprinting":
					enter_normal_state()
			elif sprint_mode == 1:  # Toggle sprint
				if moving:
					if Input.is_action_just_pressed(SPRINT) and moving_forward:
						if state == "normal":
							enter_sprint_state()
						elif state == "sprinting":
							enter_normal_state()
					elif !moving_forward and state == "sprinting":
						enter_normal_state()
				elif state == "sprinting":
					enter_normal_state()
		elif state == "sprinting":
			# If we're sprinting but now bunny hopping, revert to normal
			enter_normal_state()
	
	# Handle slide state
	if slide_enabled and on_floor:
		if crouch_mode == 0:  # Hold to crouch/slide
			if Input.is_action_pressed(CROUCH):
				if state == "sprinting" or (state == "normal" and horizontal_velocity > MIN_SLIDE_VELOCITY):
					enter_sliding_state()
			elif state == "sliding" and !Input.is_action_pressed(JUMP) and !ceiling_blocked:
				enter_normal_state()
		elif crouch_mode == 1:  # Toggle crouch/slide
			if Input.is_action_just_pressed(CROUCH):
				if state == "sprinting" or (state == "normal" and horizontal_velocity > MIN_SLIDE_VELOCITY):
					enter_sliding_state()
				elif state == "sliding" and !ceiling_blocked:
					enter_normal_state()
	
	# Handle crouch state
	if crouch_enabled and state != "sliding" and state != "grappling":
		if crouch_mode == 0:  # Hold to crouch
			if Input.is_action_pressed(CROUCH) and state != "sprinting":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !ceiling_blocked:
				enter_normal_state()
		elif crouch_mode == 1:  # Toggle crouch
			if Input.is_action_just_pressed(CROUCH):
				if state == "normal":
					enter_crouch_state()
				elif state == "crouching" and !ceiling_blocked:
					enter_normal_state()

func enter_normal_state():
	print("entering normal state")
	var prev_state = state
	if prev_state == "crouching" or prev_state == "sliding":
		CROUCH_ANIMATION.play_backwards("crouch", 0.2)
	
	# Exit weapon sprint animation if coming from sprint state
	if prev_state == "sprinting" and weapons:
		weapons.exit_sprint_animation()
		
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	print("entering crouch state")
	var prev_state = state
	print("prev_state: ", prev_state)
	# Exit weapon sprint animation if coming from sprint state
	if prev_state == "sprinting" and weapons:
		weapons.exit_sprint_animation()
		
	if prev_state == "sprinting":
		enter_sliding_state()
	elif prev_state == "sliding":
		velocity = rigid_body_3d.linear_velocity
		state = "crouching"
		speed = crouch_speed
	elif state != "grappling":
		if prev_state == "in_air":
			# If the player is in the air and crouches, play the crouch animation
			CROUCH_ANIMATION.play("crouch_air", 0.2)
		else:
			# Play the crouch animation
			CROUCH_ANIMATION.play("crouch", 0.2)
			speed = crouch_speed
		state = "crouching"

func enter_sprint_state():
	print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching" or prev_state == "sliding" and !Input.is_action_pressed("jump"):
		CROUCH_ANIMATION.play_backwards("crouch", 0.2)
	state = "sprinting"
	speed = sprint_speed
	
	# Play weapon sprint animation
	if weapons:
		weapons.play_sprint_animation()

func enter_sliding_state():
	print("entering slide state")
	var prev_state = state
	
	# Exit weapon sprint animation if coming from sprint state
	if prev_state == "sprinting" and weapons:
		weapons.exit_sprint_animation()
		
	speed = base_speed
	state = "sliding"
	rigid_body_3d.linear_velocity = Vector3.ZERO
	rigid_body_3d.angular_velocity = Vector3.ZERO
	var vel = get_real_velocity()
	if Vector3(vel.x, vel.y, vel.z).length() < 8:
		rigid_body_3d.linear_velocity = vel
		rigid_body_3d.apply_central_impulse(((Vector3(vel.x, 0, vel.z).normalized() * slide_speed) + vel))
	else:
		rigid_body_3d.linear_velocity = vel
		rigid_body_3d.apply_central_impulse((Vector3(vel.x, 0, vel.z).normalized() * vel))
	
	rigid_body_3d.apply_central_impulse(Vector3(0, -10, 0))
	#rigid_body_3d.linear_velocity = get_real_velocity()
	
	#velocity.x = velocity.x * 1.5
	#velocity.z = velocity.z * 1.5
	#speed = slide_speed
	if prev_state == "in_air":
		# If the player is in the air and slides, play the slide animation
		CROUCH_ANIMATION.play("crouch_air", 0.2)
	else:
		# Play the slide animation
		CROUCH_ANIMATION.play("crouch", 0.2)

func queue_jump() -> void:
	if AUTO_JUMP:
		jump_queued = Input.is_action_pressed("jump")
		return
	if Input.is_action_pressed("jump") and !jump_queued:
		jump_queued = true
	if Input.is_action_pressed("jump"):
		jump_queued = false

func ground_move(delta : float) -> void:
	apply_friction(float(!jump_queued), delta)
	var wishdir : Vector3 = Vector3(dir.x, 0.0, dir.z)
	wishdir = wishdir.normalized()
	#print(wishdir)
	dir_norm = wishdir
	var wishspeed : float = wishdir.length()
	wishspeed *= GROUND_SETTINGS.max_speed * haste_multiplier * speed
	accelerate(dir_norm, wishspeed, GROUND_SETTINGS.acceleration, delta)
	# Slope handling
	var collisionCounter = get_slide_collision_count() - 1

	if collisionCounter > -1:
		var collision = get_slide_collision(collisionCounter)
		if collision.get_collider():
			var normal = collision.get_normal()
			if normal.dot(Vector3.DOWN) > -0.9:
				is_on_slope = true
			else:
				# Apply gravity
				is_on_slope = false
				vel.y -= GRAVITY * delta
	# Jumping
	if jump_queued:
		vel.y = JUMP_FORCE
		jump_noise.play()
		jump_queued = false

func accelerate(target_dir : Vector3, target_speed : float, accel : float, delta : float) -> void:
	var current_speed : float = vel.dot(target_dir)
	var add_speed : float = target_speed - current_speed
	if add_speed <= 0:
		return
	var accel_speed = accel * delta * target_speed
	if accel_speed > add_speed:
		accel_speed = add_speed
	vel.x += accel_speed * target_dir.x
	vel.z += accel_speed * target_dir.z

func apply_friction(t : float, delta : float) -> void:
	var vec : Vector3 = vel
	vec.y = 0.0
	var speed : float = vec.length()
	var drop : float = 0.0
	# Only apply friction when grounded
	if is_on_floor() && !jump_queued:
		var control : float
		if speed < GROUND_SETTINGS.deceleration:
			control = GROUND_SETTINGS.deceleration
		else:
			control = speed
		drop = control * FRICTION * delta * t
	var new_speed = speed - drop
	friction = new_speed
	if new_speed < 0:
		new_speed = 0
	if new_speed > 0:
		new_speed /= speed
	vel.x *= new_speed
	vel.z *= new_speed

"""
==================
push

Can be used for rocket jumps, impact damage etc.
==================
"""
func push(force : float, dir : Vector3):
	print("pushing")

	if is_on_floor() && !jump_queued:
		print("FLOOR JUMP")
		vel.y = force * dir.y
		vel.x += force * dir.x
		vel.z += force * dir.z
	else:
		vel.y += force * 1.25 * dir.y
		vel.x += force * dir.x
		vel.z += force * dir.z


func update_camera_fov():
	# Slow down the FOV transition for a smoother effect
	var transition_speed = 0.1  # Reduced from 0.3 for slower transition
	
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 85.0, transition_speed)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, transition_speed)


func headbob_animation():
	#if weapons.Animation_Player.is_playing():
		#WEAPONBOB_ANIMATION.play("RESET", 0.5, 1)
	var moving = Vector2(abs(vel.x), abs(vel.z)).length() > 0.1
	
	# Disable headbob during sliding by returning early
	if state == "sliding":
		# If you have a slide animation, play it here
		if WEAPONBOB_ANIMATION.current_animation != "LAND" and WEAPONBOB_ANIMATION.current_animation != "slide":
			WEAPONBOB_ANIMATION.play("RESET", 1, 1)
		return
		
	if !was_on_floor and is_on_floor(): # The player just landed
			WEAPONBOB_ANIMATION.play("LAND", 0, 1)
			WEAPONBOB_ANIMATION.speed_scale = 1
			WEAPONBOB_ANIMATION.queue("RESET")
			print(WEAPONBOB_ANIMATION.current_animation)
	elif moving and is_on_floor() && WEAPONBOB_ANIMATION.current_animation != "LAND":
		var use_headbob_animation : String
		if abs(move_input.x) < abs(move_input.y):
			use_headbob_animation = "bob_horizontal"
		else:
			use_headbob_animation = "bob_vertical"
		
		var was_playing : bool = false
		if WEAPONBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true
		
		if move_input.y > 0 && move_input.x == 0:
			WEAPONBOB_ANIMATION.play(use_headbob_animation, 1, -1)
			WEAPONBOB_ANIMATION.speed_scale = -Vector2(vel.x, vel.z).length() / -GROUND_SETTINGS.max_speed
		else:
			WEAPONBOB_ANIMATION.play(use_headbob_animation, 1, 1)
			WEAPONBOB_ANIMATION.speed_scale = Vector2(vel.x, vel.z).length() / GROUND_SETTINGS.max_speed
	elif !moving and is_on_floor() && WEAPONBOB_ANIMATION.current_animation != "LAND":
		if WEAPONBOB_ANIMATION.is_playing():
			WEAPONBOB_ANIMATION.play("RESET", 1, 1)
	elif !is_on_floor() && WEAPONBOB_ANIMATION.current_animation != "LAND":
		WEAPONBOB_ANIMATION.play("RESET", 1, 1)



func _process(delta):
	var interpolation_fraction = Engine.get_physics_interpolation_fraction()
	var render_position = prev_physics_position.lerp(physics_position, interpolation_fraction)
	global_transform.origin = render_position
	input_dir = move_input
	handle_state(input_dir)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		move_input.x = (int(Input.is_action_pressed("backward")) - int(Input.is_action_pressed("forward")))
		move_input.y = (int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))
	# Setting the mouse mode
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#if Input.is_action_just_pressed("fire"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if state == "sliding":
		if Input.is_action_just_released(CROUCH):
			enter_normal_state()
		global_position = rigid_body_3d.global_position + Vector3(0,-0.5,0)
		#rigid_body_3d.angular_velocity = rigid_body_3d.angular_velocity * 1.5
	else:
		rigid_body_3d.global_rotation.y = HEAD.global_rotation.y
		rigid_body_3d.global_position = global_position + Vector3(0,0.5,0)
	
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	if state != "grappling":
		velocity = vel
	# Uncomment if you want full controller support
	#var controller_view_rotation = Input.get_vector(LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN)
	#HEAD.rotation_degrees.y -= controller_view_rotation.x * 1.5
	#HEAD.rotation_degrees.x -= controller_view_rotation.y * 1.5


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		HEAD.rotation_degrees.y -= event.relative.x * (UserPrefs.mouse_sensitivity * 0.01)
		HEAD.rotation_degrees.x -= event.relative.y * (UserPrefs.mouse_sensitivity * 0.01)

func step_noise_play() -> void:
	step_noise["event_parameter/floor_type/value"] = 1
	step_noise.play()

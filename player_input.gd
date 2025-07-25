extends MultiplayerSynchronizer

# Jump state for bunny hopping
@export var jumping := false

# Synchronized properties.
@export var direction := Vector2()
@export var yaw_rotation := 0.0  # Horizontal mouse rotation for multiplayer sync
@export var pitch_rotation := 0.0  # Vertical mouse rotation for multiplayer sync

# Weapon input
@export var shoot_input := false
@export var is_firing := false  # Synchronized firing state for client prediction
@export var beam_start_point := Vector3.ZERO
@export var beam_end_point := Vector3.ZERO
@export var target_path := NodePath()  # Synchronized target for damage

func _ready():
	# Only process for the local player
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())

func _process(delta):
	# Get the input direction using custom input mappings
	var forward = Input.get_action_strength("move_forward")
	var backward = Input.get_action_strength("move_back")
	var left = Input.get_action_strength("move_left")
	var right = Input.get_action_strength("move_right")
	
	# Calculate movement direction (forward/backward on Y axis, left/right on X axis)
	direction = Vector2(right - left, backward - forward)  # Fixed: backward - forward for correct direction
	
	# Handle jump input using custom mapping (for bunny hopping)
	jumping = Input.is_action_pressed("jump")  # Direct input check for bunny hopping
	
	# Handle weapon input
	var new_shoot_input = Input.is_action_pressed("shoot")
	if new_shoot_input != shoot_input:
		shoot_input = new_shoot_input
		if shoot_input:
			print("SHOOT ACTION PRESSED!")
		else:
			print("SHOOT ACTION RELEASED!")
	
	# Update firing state based on shoot input
	is_firing = shoot_input
	

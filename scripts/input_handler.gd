extends Node

# Singleton pattern for global access
static var instance: Node

# Input states
enum InputState {
	MAIN_MENU,
	IN_GAME,
	PAUSE_MENU,
	CONSOLE,
	OPTIONS_MENU
}

var current_state: InputState = InputState.MAIN_MENU

# References to current active systems
var current_menu: Control = null
var current_game: Node = null
var current_pause_menu: Control = null
var current_console: Control = null

func _ready():
	print("=== INPUT HANDLER _READY() CALLED ===")
	# Set up singleton
	if instance == null:
		instance = self
		# Make sure this node persists across scene changes
		process_mode = Node.PROCESS_MODE_ALWAYS
		print("=== INPUT HANDLER: Singleton initialized ===")
	else:
		print("=== INPUT HANDLER: Duplicate instance, queueing free ===")
		queue_free()
		return

func _input(event):
	# Route input based on current state
	match current_state:
		InputState.MAIN_MENU:
			handle_main_menu_input(event)
		InputState.IN_GAME:
			handle_in_game_input(event)
		InputState.PAUSE_MENU:
			handle_pause_menu_input(event)
		InputState.CONSOLE:
			handle_console_input(event)
		InputState.OPTIONS_MENU:
			handle_options_menu_input(event)
	
	# Debug: Log escape key presses
	if event.is_action_pressed("ui_cancel"):
		print("=== INPUT HANDLER: Escape pressed, current state: ", current_state, " ===")

func _unhandled_input(event):
	# Handle unhandled input (like console toggle)
	if event.is_action_pressed("toggle_console"):
		toggle_console()
		get_viewport().set_input_as_handled()

# State management
func set_state(new_state: InputState):
	print("=== INPUT HANDLER: State changing from ", current_state, " to ", new_state, " ===")
	current_state = new_state

func set_main_menu(menu: Control):
	current_menu = menu
	set_state(InputState.MAIN_MENU)

func set_in_game(game: Node):
	current_game = game
	set_state(InputState.IN_GAME)

func set_pause_menu(pause_menu: Control):
	current_pause_menu = pause_menu
	set_state(InputState.PAUSE_MENU)

func set_console(console: Control):
	current_console = console
	set_state(InputState.CONSOLE)

func set_options_menu(options_menu: Control):
	set_state(InputState.OPTIONS_MENU)

# Input handlers for each state
func handle_main_menu_input(event):
	# Main menu handles its own input
	# Just pass through to the current menu
	if current_menu and current_menu.has_method("_input"):
		current_menu._input(event)

func handle_in_game_input(event):
	# In-game input handling
	if event.is_action_pressed("ui_cancel"):
		# Show pause menu
		if current_pause_menu:
			print("=== INPUT HANDLER: Showing pause menu ===")
			current_pause_menu.visible = true
			# Free mouse for menu interaction
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			set_state(InputState.PAUSE_MENU)
			get_viewport().set_input_as_handled()
		else:
			print("=== INPUT HANDLER: No pause menu found! ===")
		return
	
	# Pass through ALL OTHER input to game systems (player, camera, etc.)
	if current_game and current_game.has_method("_input"):
		current_game._input(event)

func handle_pause_menu_input(event):
	# Pause menu input handling
	if event.is_action_pressed("ui_cancel"):
		# Hide pause menu and return to game
		if current_pause_menu:
			current_pause_menu.visible = false
			# Restore mouse capture for gameplay
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			set_state(InputState.IN_GAME)
			get_viewport().set_input_as_handled()
		return
	
	# Pass through to pause menu (blocks all other input to player)
	if current_pause_menu and current_pause_menu.has_method("_input"):
		current_pause_menu._input(event)

func handle_console_input(event):
	# Console input handling
	if event.is_action_pressed("ui_cancel"):
		# Close console
		toggle_console()
		get_viewport().set_input_as_handled()
		return
	
	# Pass through to console
	if current_console and current_console.has_method("_input"):
		current_console._input(event)

func handle_options_menu_input(event):
	# Options menu input handling
	if event.is_action_pressed("ui_cancel"):
		# Close options menu
		set_state(InputState.MAIN_MENU)
		get_viewport().set_input_as_handled()
		return

# Console management
func toggle_console():
	if current_state == InputState.CONSOLE:
		# Close console
		if current_console:
			current_console.visible = false
		set_state(InputState.IN_GAME)
		print("=== INPUT HANDLER: Console closed ===")
	else:
		# Open console
		if current_console:
			current_console.visible = true
			set_state(InputState.CONSOLE)
		print("=== INPUT HANDLER: Console opened ===")

# Utility functions
func is_in_game() -> bool:
	return current_state == InputState.IN_GAME

func is_paused() -> bool:
	return current_state == InputState.PAUSE_MENU

func is_in_menu() -> bool:
	return current_state == InputState.MAIN_MENU or current_state == InputState.OPTIONS_MENU 
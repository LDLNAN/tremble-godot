extends Control

# Console - Command-line interface accessible throughout the game

# UI References
var console_input: LineEdit
var console_output: RichTextLabel
var console_panel: Panel

# Console state
var is_visible = false
var command_history: Array[String] = []
var history_index = 0

# Available commands
var commands = {}

func _ready():
	print("Console: _ready() called")
	
	# Wait one frame to ensure all nodes are properly instantiated
	await get_tree().process_frame
	
	# Find UI references
	find_ui_references()
	
	# Set up connections
	setup_connections()
	
	# Register default commands
	register_default_commands()
	
	print("Console: _ready() completed")

func find_ui_references():
	console_input = get_node_or_null("ConsolePanel/VBoxContainer/ConsoleInput")
	console_output = get_node_or_null("ConsolePanel/VBoxContainer/ConsoleOutput")
	console_panel = get_node_or_null("ConsolePanel")
	
	print("Console: UI references found:")
	print("  - console_input: ", console_input != null)
	print("  - console_output: ", console_output != null)
	print("  - console_panel: ", console_panel != null)

func setup_connections():
	if console_input:
		console_input.text_submitted.connect(_on_console_input_submitted)
		print("Console: Input connection established")

func register_default_commands():
	# Help command
	register_command("help", _cmd_help, "Show available commands")
	
	# Clear command
	register_command("clear", _cmd_clear, "Clear console output")
	
	# Echo command
	register_command("echo", _cmd_echo, "Echo text to console")
	
	# Version command
	register_command("version", _cmd_version, "Show game version")
	
	# Quit command
	register_command("quit", _cmd_quit, "Quit the game")
	
	# Multiplayer commands
	register_command("connect", _cmd_connect, "Connect to a server (usage: connect <ip> [port])")
	register_command("host", _cmd_host, "Host a server (usage: host [port])")
	register_command("disconnect", _cmd_disconnect, "Disconnect from current server")
	register_command("status", _cmd_status, "Show network status")
	
	# Settings commands
	register_command("volume", _cmd_volume, "Set audio volume (usage: volume <master|music|sfx> <0-100>)")
	register_command("fullscreen", _cmd_fullscreen, "Toggle fullscreen mode")
	register_command("vsync", _cmd_vsync, "Toggle vsync")
	register_command("fps", _cmd_fps, "Show current FPS")
	
	# Test command
	register_command("test", _cmd_test, "Test console functionality")
	
	print("Console: Default commands registered")

func register_command(command_name: String, callback: Callable, description: String = ""):
	commands[command_name] = {
		"callback": callback,
		"description": description
	}
	print("Console: Registered command: ", command_name)

func _on_console_input_submitted(text: String):
	if text.strip_edges() == "":
		return
	
	# Add to history
	command_history.append(text)
	history_index = command_history.size()
	
	# Display command
	print_to_console("> " + text, Color.YELLOW)
	
	# Execute command
	execute_command(text)
	
	# Clear input
	if console_input:
		console_input.text = ""

func execute_command(command_line: String):
	var parts = command_line.split(" ", false)
	var command = parts[0].to_lower()
	var args = parts.slice(1)
	
	if commands.has(command):
		var cmd_data = commands[command]
		cmd_data.callback.call(args)
	else:
		print_to_console("Unknown command: " + command, Color.RED)
		print_to_console("Type 'help' for available commands", Color.GRAY)

func show_console():
	visible = true
	is_visible = true
	
	# Focus on input
	if console_input:
		console_input.grab_focus()
	
	print("Console: Console shown")

func hide_console():
	visible = false
	is_visible = false
	
	# Release focus
	if console_input:
		console_input.release_focus()
	
	print("Console: Console hidden")

func print_to_console(text: String, color: Color = Color.WHITE):
	if console_output:
		console_output.append_text("[color=" + color.to_html() + "]" + text + "[/color]\n")
		# Auto-scroll to bottom
		console_output.scroll_to_line(console_output.get_line_count() - 1)
	
	print("Console: ", text)

# Input handling for console toggle
func _unhandled_input(event):
	# Only handle toggle action when console is hidden
	if not is_visible and event is InputEventKey and event.is_action_pressed("toggle_console"):
		show_console()
		get_viewport().set_input_as_handled()

# Input handling when console is visible
func _input(event):
	# Only process input if console is visible
	if not is_visible:
		return
	
	# Console is visible - handle console-specific input
	if event is InputEventKey:
		# Handle escape to close console
		if event.is_action_pressed("ui_cancel"):
			hide_console()
			get_viewport().set_input_as_handled()
			return
		
		# Handle up/down arrows for command history
		if console_input and console_input.has_focus():
			if event.is_action_pressed("ui_up"):
				navigate_history(-1)
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_down"):
				navigate_history(1)
				get_viewport().set_input_as_handled()
		
		# Handle toggle action when console is visible
		if event.is_action_pressed("toggle_console"):
			hide_console()
			get_viewport().set_input_as_handled()

func navigate_history(direction: int):
	if command_history.size() == 0:
		return
	
	history_index += direction
	history_index = clamp(history_index, 0, command_history.size())
	
	if history_index < command_history.size():
		console_input.text = command_history[history_index]
		console_input.caret_column = console_input.text.length()
	else:
		console_input.text = ""

# Default command implementations
func _cmd_help(args: Array):
	print_to_console("Available commands:", Color.CYAN)
	for cmd_name in commands.keys():
		var cmd_data = commands[cmd_name]
		var description = cmd_data.description if cmd_data.description != "" else "No description"
		print_to_console("  " + cmd_name + " - " + description, Color.WHITE)

func _cmd_clear(args: Array):
	if console_output:
		console_output.clear()

func _cmd_echo(args: Array):
	var text = " ".join(args)
	print_to_console(text, Color.GREEN)

func _cmd_version(args: Array):
	print_to_console("Tremble v0.1.0", Color.CYAN)

func _cmd_quit(args: Array):
	print_to_console("Quitting game...", Color.YELLOW)
	get_tree().quit()

# Multiplayer command implementations
func _cmd_connect(args: Array):
	if args.size() < 1:
		print_to_console("Usage: connect <ip> [port]", Color.RED)
		return
	
	var ip = args[0]
	var port = 4433  # Default port
	
	if args.size() >= 2:
		port = args[1].to_int()
		if port <= 0 or port > 65535:
			print_to_console("Invalid port number. Must be between 1-65535", Color.RED)
			return
	
	print_to_console("Connecting to " + ip + ":" + str(port) + "...", Color.YELLOW)
	
	# Try to find multiplayer scene and connect
	var multiplayer_scene = find_multiplayer_scene()
	if multiplayer_scene:
		multiplayer_scene.connect_to_server(ip, port)
	else:
		print_to_console("No multiplayer scene found. Start a multiplayer game first.", Color.RED)

func _cmd_host(args: Array):
	var port = 4433  # Default port
	
	if args.size() >= 1:
		port = args[0].to_int()
		if port <= 0 or port > 65535:
			print_to_console("Invalid port number. Must be between 1-65535", Color.RED)
			return
	
	print_to_console("Starting server on port " + str(port) + "...", Color.YELLOW)
	
	# Try to find multiplayer scene and host
	var multiplayer_scene = find_multiplayer_scene()
	if multiplayer_scene:
		multiplayer_scene.host_server(port)
	else:
		print_to_console("No multiplayer scene found. Start a multiplayer game first.", Color.RED)

func _cmd_disconnect(args: Array):
	print_to_console("Disconnecting...", Color.YELLOW)
	
	var multiplayer_scene = find_multiplayer_scene()
	if multiplayer_scene:
		multiplayer_scene.disconnect_from_server()
	else:
		print_to_console("No multiplayer scene found.", Color.RED)

func _cmd_status(args: Array):
	var multiplayer_scene = find_multiplayer_scene()
	if multiplayer_scene:
		multiplayer_scene.show_network_status()
	else:
		print_to_console("No multiplayer scene found.", Color.RED)

# Helper function to find multiplayer scene
func find_multiplayer_scene():
	# Look for multiplayer scene in the scene tree
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "Multiplayer":
			return child
		# Also check children of children
		for grandchild in child.get_children():
			if grandchild.name == "Multiplayer":
				return grandchild
	return null

# Settings command implementations
func _cmd_volume(args: Array):
	if args.size() < 2:
		print_to_console("Usage: volume <master|music|sfx> <0-100>", Color.RED)
		return
	
	var bus_name = args[0].to_lower()
	var volume = args[1].to_float()
	
	if volume < 0 or volume > 100:
		print_to_console("Volume must be between 0-100", Color.RED)
		return
	
	# Convert percentage to decibels
	var db = linear_to_db(volume / 100.0)
	
	match bus_name:
		"master":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
			print_to_console("Master volume set to " + str(volume) + "%", Color.GREEN)
		"music":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
			print_to_console("Music volume set to " + str(volume) + "%", Color.GREEN)
		"sfx":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
			print_to_console("SFX volume set to " + str(volume) + "%", Color.GREEN)
		_:
			print_to_console("Invalid bus name. Use: master, music, or sfx", Color.RED)

func _cmd_fullscreen(args: Array):
	var current_mode = DisplayServer.window_get_mode()
	var new_mode
	
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		new_mode = DisplayServer.WINDOW_MODE_WINDOWED
		print_to_console("Switching to windowed mode", Color.YELLOW)
	else:
		new_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		print_to_console("Switching to fullscreen mode", Color.YELLOW)
	
	DisplayServer.window_set_mode(new_mode)

func _cmd_vsync(args: Array):
	var current_vsync = DisplayServer.window_get_vsync_mode()
	var new_vsync
	
	if current_vsync == DisplayServer.VSYNC_DISABLED:
		new_vsync = DisplayServer.VSYNC_ENABLED
		print_to_console("VSync enabled", Color.GREEN)
	else:
		new_vsync = DisplayServer.VSYNC_DISABLED
		print_to_console("VSync disabled", Color.YELLOW)
	
	DisplayServer.window_set_vsync_mode(new_vsync)

func _cmd_fps(args: Array):
	var fps = Engine.get_frames_per_second()
	print_to_console("Current FPS: " + str(fps), Color.CYAN)

func _cmd_test(args: Array):
	print_to_console("=== Console Test ===", Color.CYAN)
	print_to_console("Console is working!", Color.GREEN)
	print_to_console("Available commands: " + str(commands.size()), Color.YELLOW)
	print_to_console("Command history: " + str(command_history.size()) + " entries", Color.YELLOW)
	print_to_console("Console visible: " + str(is_visible), Color.YELLOW)
	print_to_console("Toggle console with: ~ (tilde key)", Color.CYAN)
	
	# Test color output
	print_to_console("Color test: ", Color.WHITE)
	print_to_console("  Red text", Color.RED)
	print_to_console("  Green text", Color.GREEN)
	print_to_console("  Blue text", Color.BLUE)
	print_to_console("  Yellow text", Color.YELLOW)
	print_to_console("  Cyan text", Color.CYAN)
	print_to_console("  Magenta text", Color.MAGENTA)
	
	# Test scene loading
	var lobby_scene = load("res://scenes/ui/lobby_screen.tscn")
	if lobby_scene:
		print_to_console("Lobby screen scene loaded successfully!", Color.GREEN)
	else:
		print_to_console("Failed to load lobby screen scene!", Color.RED)
	
	print_to_console("=== Test Complete ===", Color.CYAN)

# Public API for other scripts to use
func add_command(command_name: String, callback: Callable, description: String = ""):
	register_command(command_name, callback, description)

func log(message: String, color: Color = Color.WHITE):
	print_to_console(message, color)

func execute_console_command(command: String):
	execute_command(command) 

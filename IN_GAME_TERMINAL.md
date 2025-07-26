# 🔧 In-Game Terminal System - Tremble

## 📋 Overview

This document outlines a comprehensive in-game terminal system for Tremble, similar to Source engine games, that allows players and developers to change configuration values on the fly, execute functions, and debug the game in real-time.

---

## 🎯 Core Terminal Features

### 1. **Basic Terminal Interface**
```gdscript
# terminal.gd
extends Control

class_name InGameTerminal

signal command_executed(command: String, result: String)
signal config_changed(variable: String, old_value: Variant, new_value: Variant)

# Terminal UI Components
var terminal_output: RichTextLabel
var command_input: LineEdit
var command_history: Array[String] = []
var history_index: int = 0

# Command System
var commands: Dictionary = {}
var config_variables: Dictionary = {}
var aliases: Dictionary = {}

# Terminal State
var is_open: bool = false
var max_history: int = 100
var max_output_lines: int = 500

func _ready():
    setup_terminal_ui()
    register_default_commands()
    register_default_config_variables()
    setup_input_handling()

func setup_terminal_ui():
    # Create terminal background
    var background = ColorRect.new()
    background.color = Color(0, 0, 0, 0.8)
    background.rect_size = Vector2(800, 400)
    add_child(background)
    
    # Create output display
    terminal_output = RichTextLabel.new()
    terminal_output.rect_position = Vector2(10, 10)
    terminal_output.rect_size = Vector2(780, 340)
    terminal_output.bbcode_enabled = true
    terminal_output.scroll_following = true
    add_child(terminal_output)
    
    # Create command input
    command_input = LineEdit.new()
    command_input.rect_position = Vector2(10, 360)
    command_input.rect_size = Vector2(780, 30)
    command_input.placeholder_text = "Enter command..."
    add_child(command_input)
    
    # Connect input signals
    command_input.text_submitted.connect(_on_command_submitted)
    
    # Initially hidden
    visible = false

func setup_input_handling():
    # Bind tilde key to toggle terminal
    var input_event = InputEventKey.new()
    input_event.keycode = KEY_QUOTELEFT  # Tilde key
    InputMap.add_action("toggle_terminal")
    InputMap.action_add_event("toggle_terminal", input_event)

func _input(event):
    if event.is_action_pressed("toggle_terminal"):
        toggle_terminal()
    
    if is_open and event.is_action_pressed("ui_cancel"):
        toggle_terminal()

func toggle_terminal():
    is_open = !is_open
    visible = is_open
    
    if is_open:
        command_input.grab_focus()
        print_to_terminal("Terminal opened. Type 'help' for available commands.")
    else:
        command_input.release_focus()
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_command_submitted(command: String):
    if command.strip_edges().is_empty():
        return
    
    # Add to history
    add_to_history(command)
    
    # Execute command
    var result = execute_command(command)
    
    # Display result
    print_to_terminal("> " + command)
    if result != "":
        print_to_terminal(result)
    
    # Clear input
    command_input.text = ""
    
    # Emit signal
    command_executed.emit(command, result)

func add_to_history(command: String):
    command_history.append(command)
    if command_history.size() > max_history:
        command_history.pop_front()
    history_index = command_history.size()

func execute_command(command_string: String) -> String:
    var parts = command_string.split(" ", false)
    var command_name = parts[0].to_lower()
    var args = parts.slice(1)
    
    # Check for aliases
    if aliases.has(command_name):
        command_name = aliases[command_name]
    
    # Execute command
    if commands.has(command_name):
        var command_func = commands[command_name]
        return command_func.call(args)
    else:
        return "Unknown command: %s. Type 'help' for available commands." % command_name

func print_to_terminal(text: String, color: Color = Color.WHITE):
    var colored_text = "[color=#%s]%s[/color]" % [color.to_html(false), text]
    terminal_output.append_text(colored_text + "\n")
    
    # Limit output lines
    var lines = terminal_output.text.split("\n")
    if lines.size() > max_output_lines:
        var excess_lines = lines.size() - max_output_lines
        lines = lines.slice(excess_lines)
        terminal_output.text = "\n".join(lines)
```

---

## 🔧 Command System

### 1. **Command Registration**
```gdscript
func register_default_commands():
    # System commands
    register_command("help", _cmd_help)
    register_command("clear", _cmd_clear)
    register_command("echo", _cmd_echo)
    register_command("quit", _cmd_quit)
    register_command("exit", _cmd_quit)
    
    # Config commands
    register_command("set", _cmd_set)
    register_command("get", _cmd_get)
    register_command("list", _cmd_list)
    register_command("reset", _cmd_reset)
    
    # Network commands
    register_command("connect", _cmd_connect)
    register_command("disconnect", _cmd_disconnect)
    register_command("status", _cmd_status)
    register_command("ping", _cmd_ping)
    
    # Performance commands
    register_command("fps", _cmd_fps)
    register_command("memory", _cmd_memory)
    register_command("profile", _cmd_profile)
    
    # Game commands
    register_command("god", _cmd_god)
    register_command("noclip", _cmd_noclip)
    register_command("kill", _cmd_kill)
    register_command("respawn", _cmd_respawn)
    register_command("teleport", _cmd_teleport)
    
    # Weapon commands
    register_command("give", _cmd_give)
    register_command("ammo", _cmd_ammo)
    register_command("damage", _cmd_damage)
    
    # Debug commands
    register_command("debug", _cmd_debug)
    register_command("show", _cmd_show)
    register_command("hide", _cmd_hide)
    register_command("log", _cmd_log)

func register_command(name: String, function: Callable):
    commands[name] = function

func register_alias(alias: String, command: String):
    aliases[alias] = command
```

### 2. **System Commands**
```gdscript
func _cmd_help(args: Array) -> String:
    var help_text = "Available commands:\n"
    help_text += "System: help, clear, echo, quit, exit\n"
    help_text += "Config: set, get, list, reset\n"
    help_text += "Network: connect, disconnect, status, ping\n"
    help_text += "Performance: fps, memory, profile\n"
    help_text += "Game: god, noclip, kill, respawn, teleport\n"
    help_text += "Weapon: give, ammo, damage\n"
    help_text += "Debug: debug, show, hide, log\n"
    help_text += "\nType 'help <command>' for detailed help."
    return help_text

func _cmd_clear(args: Array) -> String:
    terminal_output.text = ""
    return "Terminal cleared."

func _cmd_echo(args: Array) -> String:
    return " ".join(args)

func _cmd_quit(args: Array) -> String:
    toggle_terminal()
    return "Terminal closed."
```

### 3. **Configuration Commands**
```gdscript
func _cmd_set(args: Array) -> String:
    if args.size() < 2:
        return "Usage: set <variable> <value>"
    
    var variable = args[0]
    var value_string = " ".join(args.slice(1))
    
    if not config_variables.has(variable):
        return "Unknown variable: %s" % variable
    
    var config = config_variables[variable]
    var old_value = config.value
    
    # Parse and validate value
    var new_value = parse_config_value(value_string, config.type)
    if new_value == null:
        return "Invalid value for %s (type: %s)" % [variable, config.type]
    
    # Set the value
    config.value = new_value
    config_changed.emit(variable, old_value, new_value)
    
    # Apply the change
    if config.apply_function:
        config.apply_function.call(new_value)
    
    return "Set %s = %s" % [variable, str(new_value)]

func _cmd_get(args: Array) -> String:
    if args.size() < 1:
        return "Usage: get <variable>"
    
    var variable = args[0]
    if not config_variables.has(variable):
        return "Unknown variable: %s" % variable
    
    var config = config_variables[variable]
    return "%s = %s (type: %s)" % [variable, str(config.value), config.type]

func _cmd_list(args: Array) -> String:
    var list_text = "Configuration variables:\n"
    for variable in config_variables:
        var config = config_variables[variable]
        list_text += "  %s = %s\n" % [variable, str(config.value)]
    return list_text

func _cmd_reset(args: Array) -> String:
    if args.size() < 1:
        return "Usage: reset <variable>"
    
    var variable = args[0]
    if not config_variables.has(variable):
        return "Unknown variable: %s" % variable
    
    var config = config_variables[variable]
    var old_value = config.value
    config.value = config.default_value
    
    if config.apply_function:
        config.apply_function.call(config.default_value)
    
    config_changed.emit(variable, old_value, config.default_value)
    return "Reset %s to %s" % [variable, str(config.default_value)]
```

---

## ⚙️ Configuration System

### 1. **Config Variable Registration**
```gdscript
func register_default_config_variables():
    # Graphics settings
    register_config_variable("fov", "float", 120.0, 60.0, 180.0, _apply_fov)
    register_config_variable("sensitivity", "float", 1.0, 0.1, 10.0, _apply_sensitivity)
    register_config_variable("vsync", "bool", true, null, null, _apply_vsync)
    register_config_variable("fullscreen", "bool", false, null, null, _apply_fullscreen)
    
    # Audio settings
    register_config_variable("master_volume", "float", 1.0, 0.0, 1.0, _apply_master_volume)
    register_config_variable("music_volume", "float", 0.5, 0.0, 1.0, _apply_music_volume)
    register_config_variable("sfx_volume", "float", 1.0, 0.0, 1.0, _apply_sfx_volume)
    
    # Network settings
    register_config_variable("max_ping", "int", 100, 10, 1000, _apply_max_ping)
    register_config_variable("auto_reconnect", "bool", true, null, null, _apply_auto_reconnect)
    register_config_variable("packet_loss_threshold", "float", 0.05, 0.0, 1.0, _apply_packet_loss_threshold)
    
    # Gameplay settings
    register_config_variable("infinite_ammo", "bool", false, null, null, _apply_infinite_ammo)
    register_config_variable("god_mode", "bool", false, null, null, _apply_god_mode)
    register_config_variable("noclip", "bool", false, null, null, _apply_noclip)
    register_config_variable("vampirism_amount", "float", 0.2, 0.0, 1.0, _apply_vampirism)
    
    # Performance settings
    register_config_variable("show_fps", "bool", false, null, null, _apply_show_fps)
    register_config_variable("show_performance", "bool", false, null, null, _apply_show_performance)
    register_config_variable("debug_shapes", "bool", false, null, null, _apply_debug_shapes)

func register_config_variable(name: String, type: String, default_value: Variant, min_value: Variant = null, max_value: Variant = null, apply_function: Callable = null):
    config_variables[name] = {
        "type": type,
        "value": default_value,
        "default_value": default_value,
        "min_value": min_value,
        "max_value": max_value,
        "apply_function": apply_function
    }

func parse_config_value(value_string: String, type: String) -> Variant:
    match type:
        "bool":
            var lower = value_string.to_lower()
            if lower in ["true", "1", "yes", "on"]:
                return true
            elif lower in ["false", "0", "no", "off"]:
                return false
            else:
                return null
        "int":
            if value_string.is_valid_int():
                return value_string.to_int()
            else:
                return null
        "float":
            if value_string.is_valid_float():
                return value_string.to_float()
            else:
                return null
        "string":
            return value_string
        _:
            return null
```

### 2. **Config Application Functions**
```gdscript
func _apply_fov(value: float):
    var player = get_node_or_null("/root/Game/Player")
    if player and player.camera:
        player.camera.fov = value

func _apply_sensitivity(value: float):
    var player = get_node_or_null("/root/Game/Player")
    if player:
        player.mouse_sensitivity = value

func _apply_vsync(value: bool):
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)

func _apply_fullscreen(value: bool):
    if value:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_master_volume(value: float):
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _apply_music_volume(value: float):
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _apply_sfx_volume(value: float):
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func _apply_infinite_ammo(value: bool):
    var player = get_node_or_null("/root/Game/Player")
    if player and player.player_manager and player.player_manager.get_weapon_system():
        var weapon_system = player.player_manager.get_weapon_system()
        if weapon_system.current_weapon:
            weapon_system.current_weapon.infinite_ammo = value

func _apply_god_mode(value: bool):
    var player = get_node_or_null("/root/Game/Player")
    if player and player.player_manager and player.player_manager.get_health_system():
        var health_system = player.player_manager.get_health_system()
        health_system.god_mode = value

func _apply_noclip(value: bool):
    var player = get_node_or_null("/root/Game/Player")
    if player:
        player.noclip_enabled = value

func _apply_vampirism(value: float):
    var gamemode_config = get_node_or_null("/root/Game/GamemodeConfig")
    if gamemode_config:
        gamemode_config.vampirism_amount = value
```

---

## 🌐 Network Commands

### 1. **Connection Commands**
```gdscript
func _cmd_connect(args: Array) -> String:
    if args.size() < 1:
        return "Usage: connect <ip:port>"
    
    var address = args[0]
    var parts = address.split(":")
    if parts.size() != 2:
        return "Invalid address format. Use: ip:port"
    
    var ip = parts[0]
    var port = parts[1].to_int()
    
    if not port > 0:
        return "Invalid port number"
    
    # Attempt connection
    var network_manager = get_node_or_null("/root/NetworkManager")
    if network_manager:
        network_manager.connect_to_server(ip, port)
        return "Connecting to %s:%d..." % [ip, port]
    else:
        return "Network manager not found"

func _cmd_disconnect(args: Array) -> String:
    var network_manager = get_node_or_null("/root/NetworkManager")
    if network_manager:
        network_manager.disconnect_from_server()
        return "Disconnected from server"
    else:
        return "Network manager not found"

func _cmd_status(args: Array) -> String:
    var network_manager = get_node_or_null("/root/NetworkManager")
    if not network_manager:
        return "Network manager not found"
    
    var status = network_manager.get_connection_status()
    var status_text = "Network Status:\n"
    status_text += "  Connected: %s\n" % str(status.connected)
    status_text += "  Server: %s\n" % status.server_address
    status_text += "  Latency: %d ms\n" % status.latency
    status_text += "  Packet Loss: %.2f%%\n" % (status.packet_loss * 100)
    return status_text

func _cmd_ping(args: Array) -> String:
    var network_manager = get_node_or_null("/root/NetworkManager")
    if network_manager:
        var ping = network_manager.get_ping()
        return "Ping: %d ms" % ping
    else:
        return "Network manager not found"
```

---

## 🎮 Game Commands

### 1. **Player Commands**
```gdscript
func _cmd_god(args: Array) -> String:
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var health_system = player.player_manager.get_health_system()
    health_system.god_mode = !health_system.god_mode
    return "God mode: %s" % ("ON" if health_system.god_mode else "OFF")

func _cmd_noclip(args: Array) -> String:
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    player.noclip_enabled = !player.noclip_enabled
    return "Noclip: %s" % ("ON" if player.noclip_enabled else "OFF")

func _cmd_kill(args: Array) -> String:
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var health_system = player.player_manager.get_health_system()
    health_system.take_damage(health_system.health, null)
    return "Player killed"

func _cmd_respawn(args: Array) -> String:
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var health_system = player.player_manager.get_health_system()
    health_system.respawn()
    return "Player respawned"

func _cmd_teleport(args: Array) -> String:
    if args.size() < 3:
        return "Usage: teleport <x> <y> <z>"
    
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var x = args[0].to_float()
    var y = args[1].to_float()
    var z = args[2].to_float()
    
    player.global_position = Vector3(x, y, z)
    return "Teleported to (%.1f, %.1f, %.1f)" % [x, y, z]
```

### 2. **Weapon Commands**
```gdscript
func _cmd_give(args: Array) -> String:
    if args.size() < 1:
        return "Usage: give <weapon_name>"
    
    var weapon_name = args[0]
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var weapon_system = player.player_manager.get_weapon_system()
    if weapon_system.give_weapon(weapon_name):
        return "Given %s" % weapon_name
    else:
        return "Unknown weapon: %s" % weapon_name

func _cmd_ammo(args: Array) -> String:
    if args.size() < 1:
        return "Usage: ammo <amount>"
    
    var amount = args[0].to_int()
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var weapon_system = player.player_manager.get_weapon_system()
    if weapon_system.current_weapon:
        weapon_system.current_weapon.current_ammo = amount
        return "Set ammo to %d" % amount
    else:
        return "No weapon equipped"

func _cmd_damage(args: Array) -> String:
    if args.size() < 1:
        return "Usage: damage <amount>"
    
    var amount = args[0].to_float()
    var player = get_node_or_null("/root/Game/Player")
    if not player:
        return "Player not found"
    
    var weapon_system = player.player_manager.get_weapon_system()
    if weapon_system.current_weapon:
        weapon_system.current_weapon.damage = amount
        return "Set weapon damage to %.1f" % amount
    else:
        return "No weapon equipped"
```

---

## 📊 Performance Commands

### 1. **Performance Monitoring**
```gdscript
func _cmd_fps(args: Array) -> String:
    var current_fps = Engine.get_frames_per_second()
    var target_fps = Engine.get_target_fps()
    return "FPS: %d/%d" % [current_fps, target_fps]

func _cmd_memory(args: Array) -> String:
    var dynamic_memory = OS.get_dynamic_memory_usage()
    var static_memory = OS.get_static_memory_usage()
    var total_memory = dynamic_memory + static_memory
    
    return "Memory Usage:\n  Dynamic: %.1f MB\n  Static: %.1f MB\n  Total: %.1f MB" % [
        dynamic_memory / 1024 / 1024,
        static_memory / 1024 / 1024,
        total_memory / 1024 / 1024
    ]

func _cmd_profile(args: Array) -> String:
    var profiler = get_node_or_null("/root/PerformanceProfiler")
    if not profiler:
        return "Performance profiler not available"
    
    var summary = profiler.get_profile_summary()
    var profile_text = "Function Profile:\n"
    
    for function_name in summary:
        var profile = summary[function_name]
        profile_text += "  %s:\n" % function_name
        profile_text += "    Avg: %.3f ms\n" % profile.average_time
        profile_text += "    Max: %.3f ms\n" % profile.max_time
        profile_text += "    Calls: %d\n" % profile.call_count
    
    return profile_text
```

---

## 🐛 Debug Commands

### 1. **Debug and Visualization**
```gdscript
func _cmd_debug(args: Array) -> String:
    if args.size() < 1:
        return "Usage: debug <feature> [on/off]"
    
    var feature = args[0]
    var enabled = true
    if args.size() > 1:
        enabled = args[1].to_lower() == "on"
    
    match feature:
        "shapes":
            _apply_debug_shapes(enabled)
            return "Debug shapes: %s" % ("ON" if enabled else "OFF")
        "collision":
            _apply_debug_collision(enabled)
            return "Debug collision: %s" % ("ON" if enabled else "OFF")
        "network":
            _apply_debug_network(enabled)
            return "Debug network: %s" % ("ON" if enabled else "OFF")
        _:
            return "Unknown debug feature: %s" % feature

func _cmd_show(args: Array) -> String:
    if args.size() < 1:
        return "Usage: show <element>"
    
    var element = args[0]
    match element:
        "fps":
            _apply_show_fps(true)
            return "FPS counter shown"
        "performance":
            _apply_show_performance(true)
            return "Performance overlay shown"
        "hud":
            _show_hud(true)
            return "HUD shown"
        _:
            return "Unknown element: %s" % element

func _cmd_hide(args: Array) -> String:
    if args.size() < 1:
        return "Usage: hide <element>"
    
    var element = args[0]
    match element:
        "fps":
            _apply_show_fps(false)
            return "FPS counter hidden"
        "performance":
            _apply_show_performance(false)
            return "Performance overlay hidden"
        "hud":
            _show_hud(false)
            return "HUD hidden"
        _:
            return "Unknown element: %s" % element

func _cmd_log(args: Array) -> String:
    if args.size() < 1:
        return "Usage: log <level> <message>"
    
    var level = args[0].to_lower()
    var message = " ".join(args.slice(1))
    
    match level:
        "debug":
            print_debug(message)
        "info":
            print_info(message)
        "warning":
            print_warning(message)
        "error":
            print_error(message)
        _:
            return "Unknown log level: %s" % level
    
    return "Logged: [%s] %s" % [level.to_upper(), message]
```

---

## 💾 Terminal Persistence

### 1. **Command History and Aliases**
```gdscript
func save_terminal_state():
    var state = {
        "command_history": command_history,
        "aliases": aliases,
        "config_variables": {}
    }
    
    # Save current config values
    for variable in config_variables:
        state.config_variables[variable] = config_variables[variable].value
    
    var file = FileAccess.open("user://terminal_state.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(state))
        file.close()

func load_terminal_state():
    if not FileAccess.file_exists("user://terminal_state.json"):
        return
    
    var file = FileAccess.open("user://terminal_state.json", FileAccess.READ)
    if not file:
        return
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        return
    
    var state = json.data
    
    # Restore command history
    if state.has("command_history"):
        command_history = state.command_history
    
    # Restore aliases
    if state.has("aliases"):
        aliases = state.aliases
    
    # Restore config values
    if state.has("config_variables"):
        for variable in state.config_variables:
            if config_variables.has(variable):
                var value = state.config_variables[variable]
                config_variables[variable].value = value
                if config_variables[variable].apply_function:
                    config_variables[variable].apply_function.call(value)
```

---

## 📋 Implementation Checklist

### Phase 1: Core Terminal
- [ ] Implement basic terminal UI
- [ ] Add command parsing and execution
- [ ] Create command history system
- [ ] Add input handling and key bindings

### Phase 2: Configuration System
- [ ] Implement config variable registration
- [ ] Add config parsing and validation
- [ ] Create config application functions
- [ ] Add config persistence

### Phase 3: Command Library
- [ ] Add system commands (help, clear, echo, quit)
- [ ] Add config commands (set, get, list, reset)
- [ ] Add network commands (connect, disconnect, status, ping)
- [ ] Add performance commands (fps, memory, profile)

### Phase 4: Game Commands
- [ ] Add player commands (god, noclip, kill, respawn, teleport)
- [ ] Add weapon commands (give, ammo, damage)
- [ ] Add debug commands (debug, show, hide, log)
- [ ] Add game-specific commands

### Phase 5: Advanced Features
- [ ] Add command aliases
- [ ] Implement auto-completion
- [ ] Add command suggestions
- [ ] Create terminal themes and customization

### Phase 6: Integration
- [ ] Integrate with performance monitoring
- [ ] Add error handling and validation
- [ ] Create command documentation
- [ ] Add terminal state persistence

---

This comprehensive in-game terminal system provides powerful debugging and configuration capabilities similar to Source engine games, enabling both players and developers to interact with the game in real-time. 
# 💾 Data Persistence & Server Architecture - Tremble

## 📋 Overview

This document outlines comprehensive data persistence systems and server architecture for Tremble, covering how to save player stats, settings, leaderboards, and create standalone dedicated servers.

---

## 💾 Data Persistence Systems

### 1. **Data Manager Singleton**
```gdscript
# data_manager.gd
extends Node

class_name DataManager

signal data_saved(data_type: String, success: bool)
signal data_loaded(data_type: String, success: bool)
signal data_corrupted(data_type: String, error: String)

# Data types
enum DataType {
    PLAYER_STATS,
    SETTINGS,
    LEADERBOARD,
    MATCH_HISTORY,
    TERMINAL_STATE,
    PERFORMANCE_DATA
}

# File paths
var data_paths = {
    DataType.PLAYER_STATS: "user://player_stats.json",
    DataType.SETTINGS: "user://settings.json",
    DataType.LEADERBOARD: "user://leaderboard.json",
    DataType.MATCH_HISTORY: "user://match_history.json",
    DataType.TERMINAL_STATE: "user://terminal_state.json",
    DataType.PERFORMANCE_DATA: "user://performance_data.json"
}

# Backup paths
var backup_paths = {
    DataType.PLAYER_STATS: "user://backups/player_stats_backup.json",
    DataType.SETTINGS: "user://backups/settings_backup.json",
    DataType.LEADERBOARD: "user://backups/leaderboard_backup.json"
}

# Data schemas for validation
var data_schemas = {
    DataType.PLAYER_STATS: {
        "version": "string",
        "player_id": "string",
        "username": "string",
        "stats": {
            "matches_played": "int",
            "wins": "int",
            "losses": "int",
            "kills": "int",
            "deaths": "int",
            "accuracy": "float",
            "playtime_hours": "float"
        },
        "rating": {
            "current": "float",
            "deviation": "float",
            "volatility": "float"
        },
        "last_updated": "string"
    },
    DataType.SETTINGS: {
        "version": "string",
        "graphics": {
            "resolution": "string",
            "fullscreen": "bool",
            "vsync": "bool",
            "fov": "float",
            "quality": "string"
        },
        "audio": {
            "master_volume": "float",
            "music_volume": "float",
            "sfx_volume": "float"
        },
        "controls": {
            "mouse_sensitivity": "float",
            "invert_y": "bool",
            "key_bindings": "dictionary"
        },
        "network": {
            "max_ping": "int",
            "auto_reconnect": "bool"
        }
    }
}

func _ready():
    setup_data_directories()
    load_all_data()

func setup_data_directories():
    # Create necessary directories
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("backups"):
        dir.make_dir("backups")
    if not dir.dir_exists("logs"):
        dir.make_dir("logs")
    if not dir.dir_exists("temp"):
        dir.make_dir("temp")

func save_data(data_type: DataType, data: Dictionary) -> bool:
    var file_path = data_paths[data_type]
    
    # Validate data against schema
    if not validate_data(data_type, data):
        data_corrupted.emit(DataType.keys()[data_type], "Data validation failed")
        return false
    
    # Create backup before saving
    if backup_paths.has(data_type):
        create_backup(data_type)
    
    # Save data
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if not file:
        data_saved.emit(DataType.keys()[data_type], false)
        return false
    
    var json_string = JSON.stringify(data, "\t")
    file.store_string(json_string)
    file.close()
    
    data_saved.emit(DataType.keys()[data_type], true)
    return true

func load_data(data_type: DataType) -> Dictionary:
    var file_path = data_paths[data_type]
    
    if not FileAccess.file_exists(file_path):
        var default_data = get_default_data(data_type)
        save_data(data_type, default_data)
        return default_data
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        data_loaded.emit(DataType.keys()[data_type], false)
        return get_default_data(data_type)
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        data_corrupted.emit(DataType.keys()[data_type], "JSON parsing failed")
        return get_default_data(data_type)
    
    var data = json.data
    
    # Validate loaded data
    if not validate_data(data_type, data):
        data_corrupted.emit(DataType.keys()[data_type], "Data validation failed")
        return get_default_data(data_type)
    
    data_loaded.emit(DataType.keys()[data_type], true)
    return data

func validate_data(data_type: DataType, data: Dictionary) -> bool:
    if not data_schemas.has(data_type):
        return true  # No schema defined, assume valid
    
    var schema = data_schemas[data_type]
    return validate_against_schema(data, schema)

func validate_against_schema(data: Dictionary, schema: Dictionary) -> bool:
    for key in schema:
        if not data.has(key):
            return false
        
        var expected_type = schema[key]
        var actual_value = data[key]
        
        if expected_type is Dictionary:
            if not actual_value is Dictionary:
                return false
            if not validate_against_schema(actual_value, expected_type):
                return false
        else:
            if not is_correct_type(actual_value, expected_type):
                return false
    
    return true

func is_correct_type(value: Variant, expected_type: String) -> bool:
    match expected_type:
        "string":
            return value is String
        "int":
            return value is int
        "float":
            return value is float
        "bool":
            return value is bool
        "dictionary":
            return value is Dictionary
        "array":
            return value is Array
        _:
            return true

func create_backup(data_type: DataType):
    var source_path = data_paths[data_type]
    var backup_path = backup_paths[data_type]
    
    if not FileAccess.file_exists(source_path):
        return
    
    var source_file = FileAccess.open(source_path, FileAccess.READ)
    if not source_file:
        return
    
    var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
    if not backup_file:
        source_file.close()
        return
    
    backup_file.store_string(source_file.get_as_text())
    source_file.close()
    backup_file.close()

func restore_from_backup(data_type: DataType) -> bool:
    var backup_path = backup_paths[data_type]
    var main_path = data_paths[data_type]
    
    if not FileAccess.file_exists(backup_path):
        return false
    
    var backup_file = FileAccess.open(backup_path, FileAccess.READ)
    if not backup_file:
        return false
    
    var main_file = FileAccess.open(main_path, FileAccess.WRITE)
    if not main_file:
        backup_file.close()
        return false
    
    main_file.store_string(backup_file.get_as_text())
    backup_file.close()
    main_file.close()
    
    return true

func get_default_data(data_type: DataType) -> Dictionary:
    match data_type:
        DataType.PLAYER_STATS:
            return {
                "version": "1.0",
                "player_id": "",
                "username": "",
                "stats": {
                    "matches_played": 0,
                    "wins": 0,
                    "losses": 0,
                    "kills": 0,
                    "deaths": 0,
                    "accuracy": 0.0,
                    "playtime_hours": 0.0
                },
                "rating": {
                    "current": 1500.0,
                    "deviation": 350.0,
                    "volatility": 0.06
                },
                "last_updated": Time.get_datetime_string_from_system()
            }
        DataType.SETTINGS:
            return {
                "version": "1.0",
                "graphics": {
                    "resolution": "1920x1080",
                    "fullscreen": false,
                    "vsync": true,
                    "fov": 120.0,
                    "quality": "high"
                },
                "audio": {
                    "master_volume": 1.0,
                    "music_volume": 0.5,
                    "sfx_volume": 1.0
                },
                "controls": {
                    "mouse_sensitivity": 1.0,
                    "invert_y": false,
                    "key_bindings": {}
                },
                "network": {
                    "max_ping": 100,
                    "auto_reconnect": true
                }
            }
        _:
            return {}
```

### 2. **Player Stats System**
```gdscript
# player_stats_manager.gd
extends Node

class_name PlayerStatsManager

signal stats_updated(stats: Dictionary)
signal achievement_unlocked(achievement: String)

var data_manager: DataManager
var current_stats: Dictionary = {}
var achievements: Array[String] = []

func _ready():
    data_manager = get_node("/root/DataManager")
    load_player_stats()

func load_player_stats():
    current_stats = data_manager.load_data(DataManager.DataType.PLAYER_STATS)
    
    # Apply stats to game systems
    apply_stats_to_game()

func save_player_stats():
    # Update timestamp
    current_stats.last_updated = Time.get_datetime_string_from_system()
    
    # Save to file
    var success = data_manager.save_data(DataManager.DataType.PLAYER_STATS, current_stats)
    if success:
        stats_updated.emit(current_stats)

func update_match_result(won: bool, kills: int, deaths: int, accuracy: float):
    current_stats.stats.matches_played += 1
    
    if won:
        current_stats.stats.wins += 1
    else:
        current_stats.stats.losses += 1
    
    current_stats.stats.kills += kills
    current_stats.stats.deaths += deaths
    
    # Update accuracy (rolling average)
    var total_shots = current_stats.stats.matches_played
    current_stats.stats.accuracy = (current_stats.stats.accuracy * (total_shots - 1) + accuracy) / total_shots
    
    # Check for achievements
    check_achievements()
    
    # Save stats
    save_player_stats()

func update_rating(new_rating: float, new_deviation: float, new_volatility: float):
    current_stats.rating.current = new_rating
    current_stats.rating.deviation = new_deviation
    current_stats.rating.volatility = new_volatility
    
    save_player_stats()

func check_achievements():
    var new_achievements = []
    
    # First win
    if current_stats.stats.wins == 1 and not "first_win" in achievements:
        new_achievements.append("first_win")
    
    # 10 wins
    if current_stats.stats.wins >= 10 and not "veteran" in achievements:
        new_achievements.append("veteran")
    
    # 100 kills
    if current_stats.stats.kills >= 100 and not "century" in achievements:
        new_achievements.append("century")
    
    # Perfect accuracy (100% in a match)
    if current_stats.stats.accuracy >= 1.0 and not "sharpshooter" in achievements:
        new_achievements.append("sharpshooter")
    
    # Unlock new achievements
    for achievement in new_achievements:
        achievements.append(achievement)
        achievement_unlocked.emit(achievement)

func apply_stats_to_game():
    # Apply settings to game systems
    var settings = data_manager.load_data(DataManager.DataType.SETTINGS)
    
    # Apply graphics settings
    if settings.has("graphics"):
        apply_graphics_settings(settings.graphics)
    
    # Apply audio settings
    if settings.has("audio"):
        apply_audio_settings(settings.audio)
    
    # Apply control settings
    if settings.has("controls"):
        apply_control_settings(settings.controls)

func apply_graphics_settings(graphics: Dictionary):
    if graphics.has("fullscreen"):
        DisplayServer.window_set_mode(
            DisplayServer.WINDOW_MODE_FULLSCREEN if graphics.fullscreen 
            else DisplayServer.WINDOW_MODE_WINDOWED
        )
    
    if graphics.has("vsync"):
        DisplayServer.window_set_vsync_mode(
            DisplayServer.VSYNC_ENABLED if graphics.vsync 
            else DisplayServer.VSYNC_DISABLED
        )
    
    if graphics.has("fov"):
        var player = get_node_or_null("/root/Game/Player")
        if player and player.camera:
            player.camera.fov = graphics.fov

func apply_audio_settings(audio: Dictionary):
    if audio.has("master_volume"):
        AudioServer.set_bus_volume_db(
            AudioServer.get_bus_index("Master"), 
            linear_to_db(audio.master_volume)
        )
    
    if audio.has("music_volume"):
        AudioServer.set_bus_volume_db(
            AudioServer.get_bus_index("Music"), 
            linear_to_db(audio.music_volume)
        )
    
    if audio.has("sfx_volume"):
        AudioServer.set_bus_volume_db(
            AudioServer.get_bus_index("SFX"), 
            linear_to_db(audio.sfx_volume)
        )

func apply_control_settings(controls: Dictionary):
    if controls.has("mouse_sensitivity"):
        var player = get_node_or_null("/root/Game/Player")
        if player:
            player.mouse_sensitivity = controls.mouse_sensitivity
```

### 3. **Leaderboard System**
```gdscript
# leaderboard_manager.gd
extends Node

class_name LeaderboardManager

signal leaderboard_updated()
signal player_rank_changed(old_rank: int, new_rank: int)

var data_manager: DataManager
var leaderboard_data: Dictionary = {}
var player_rankings: Array[Dictionary] = []

func _ready():
    data_manager = get_node("/root/DataManager")
    load_leaderboard()

func load_leaderboard():
    leaderboard_data = data_manager.load_data(DataManager.DataType.LEADERBOARD)
    
    if not leaderboard_data.has("players"):
        leaderboard_data.players = []
    
    if not leaderboard_data.has("last_updated"):
        leaderboard_data.last_updated = Time.get_datetime_string_from_system()
    
    update_player_rankings()

func save_leaderboard():
    leaderboard_data.last_updated = Time.get_datetime_string_from_system()
    data_manager.save_data(DataManager.DataType.LEADERBOARD, leaderboard_data)
    leaderboard_updated.emit()

func add_player_to_leaderboard(player_id: String, username: String, rating: float, stats: Dictionary):
    var player_entry = {
        "player_id": player_id,
        "username": username,
        "rating": rating,
        "stats": stats,
        "last_updated": Time.get_datetime_string_from_system()
    }
    
    # Check if player already exists
    var existing_index = -1
    for i in range(leaderboard_data.players.size()):
        if leaderboard_data.players[i].player_id == player_id:
            existing_index = i
            break
    
    if existing_index >= 0:
        # Update existing player
        var old_rating = leaderboard_data.players[existing_index].rating
        leaderboard_data.players[existing_index] = player_entry
        
        # Check for rank change
        var old_rank = get_player_rank(player_id)
        update_player_rankings()
        var new_rank = get_player_rank(player_id)
        
        if old_rank != new_rank:
            player_rank_changed.emit(old_rank, new_rank)
    else:
        # Add new player
        leaderboard_data.players.append(player_entry)
        update_player_rankings()
    
    save_leaderboard()

func update_player_rankings():
    # Sort players by rating (descending)
    leaderboard_data.players.sort_custom(func(a, b): return a.rating > b.rating)
    
    # Update rankings
    player_rankings.clear()
    for i in range(leaderboard_data.players.size()):
        var player = leaderboard_data.players[i]
        player_rankings.append({
            "rank": i + 1,
            "player_id": player.player_id,
            "username": player.username,
            "rating": player.rating,
            "stats": player.stats
        })

func get_player_rank(player_id: String) -> int:
    for ranking in player_rankings:
        if ranking.player_id == player_id:
            return ranking.rank
    return -1

func get_top_players(limit: int = 10) -> Array[Dictionary]:
    return player_rankings.slice(0, limit)

func get_players_in_range(start_rank: int, end_rank: int) -> Array[Dictionary]:
    if start_rank < 1 or end_rank > player_rankings.size():
        return []
    
    return player_rankings.slice(start_rank - 1, end_rank)

func search_player_by_name(username: String) -> Dictionary:
    for player in leaderboard_data.players:
        if player.username.to_lower().contains(username.to_lower()):
            return player
    return {}

func get_leaderboard_stats() -> Dictionary:
    if player_rankings.is_empty():
        return {}
    
    var total_players = player_rankings.size()
    var avg_rating = 0.0
    var total_matches = 0
    
    for player in player_rankings:
        avg_rating += player.rating
        total_matches += player.stats.matches_played
    
    avg_rating /= total_players
    
    return {
        "total_players": total_players,
        "average_rating": avg_rating,
        "total_matches": total_matches,
        "last_updated": leaderboard_data.last_updated
    }
```

---

## 🖥️ Server Architecture

### 1. **Dedicated Server System**
```gdscript
# dedicated_server.gd
extends Node

class_name DedicatedServer

signal server_started(port: int)
signal server_stopped()
signal player_connected(player_id: int, player_info: Dictionary)
signal player_disconnected(player_id: int)

# Server configuration
var server_config: Dictionary = {
    "port": 4433,
    "max_players": 16,
    "server_name": "Tremble Server",
    "gamemode": "duel",
    "map": "arena_01",
    "password": "",
    "public": true
}

# Server state
var is_running: bool = false
var connected_players: Dictionary = {}
var server_start_time: float = 0.0
var match_manager: Node
var player_manager: Node

func _ready():
    # Load server configuration
    load_server_config()
    
    # Set up server managers
    setup_server_managers()
    
    # Handle headless mode
    if OS.has_feature("dedicated_server"):
        start_server()

func load_server_config():
    var config_file = "server_config.json"
    if FileAccess.file_exists(config_file):
        var file = FileAccess.open(config_file, FileAccess.READ)
        if file:
            var json_string = file.get_as_text()
            file.close()
            
            var json = JSON.new()
            if json.parse(json_string) == OK:
                server_config.merge(json.data, true)

func setup_server_managers():
    # Create match manager
    match_manager = preload("res://scripts/match_manager.gd").new()
    add_child(match_manager)
    
    # Create player manager
    player_manager = preload("res://scripts/player_manager.gd").new()
    add_child(player_manager)

func start_server():
    if is_running:
        return false
    
    # Create multiplayer peer
    var peer = ENetMultiplayerPeer.new()
    var result = peer.create_server(server_config.port, server_config.max_players)
    
    if result != OK:
        print("Failed to create server on port %d" % server_config.port)
        return false
    
    # Set up multiplayer
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    
    # Start server
    is_running = true
    server_start_time = Time.get_ticks_msec()
    
    print("Dedicated server started on port %d" % server_config.port)
    server_started.emit(server_config.port)
    
    return true

func stop_server():
    if not is_running:
        return
    
    # Disconnect all players
    for player_id in connected_players:
        disconnect_player(player_id)
    
    # Stop multiplayer
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null
    
    is_running = false
    connected_players.clear()
    
    print("Dedicated server stopped")
    server_stopped.emit()

func _on_player_connected(id: int):
    print("Player %d connected" % id)
    
    var player_info = {
        "id": id,
        "username": "Player_%d" % id,
        "connect_time": Time.get_ticks_msec()
    }
    
    connected_players[id] = player_info
    player_connected.emit(id, player_info)
    
    # Spawn player
    if player_manager:
        player_manager.spawn_player(id)

func _on_player_disconnected(id: int):
    print("Player %d disconnected" % id)
    
    if connected_players.has(id):
        connected_players.erase(id)
        player_disconnected.emit(id)
    
    # Remove player
    if player_manager:
        player_manager.remove_player(id)

func disconnect_player(player_id: int):
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.disconnect_peer(player_id)

func get_server_info() -> Dictionary:
    return {
        "name": server_config.server_name,
        "port": server_config.port,
        "max_players": server_config.max_players,
        "current_players": connected_players.size(),
        "gamemode": server_config.gamemode,
        "map": server_config.map,
        "uptime": (Time.get_ticks_msec() - server_start_time) / 1000.0,
        "public": server_config.public
    }

func _process(delta):
    if not is_running:
        return
    
    # Update server logic
    update_server_logic(delta)
    
    # Check for server shutdown conditions
    check_shutdown_conditions()

func update_server_logic(delta):
    # Update match manager
    if match_manager:
        match_manager.update(delta)
    
    # Update player manager
    if player_manager:
        player_manager.update(delta)

func check_shutdown_conditions():
    # Check if all players disconnected
    if connected_players.is_empty() and server_config.auto_shutdown:
        print("No players connected, shutting down server")
        stop_server()
        get_tree().quit()

func _exit_tree():
    if is_running:
        stop_server()
```

### 2. **Server Configuration**
```gdscript
# server_config.gd
extends Resource

class_name ServerConfig

@export var server_name: String = "Tremble Server"
@export var port: int = 4433
@export var max_players: int = 16
@export var gamemode: String = "duel"
@export var map: String = "arena_01"
@export var password: String = ""
@export var public: bool = true

# Advanced settings
@export var auto_shutdown: bool = false
@export var auto_restart: bool = false
@export var max_uptime_hours: float = 24.0
@export var backup_interval_minutes: float = 30.0

# Performance settings
@export var tick_rate: int = 60
@export var max_ping: int = 200
@export var packet_loss_threshold: float = 0.1

# Security settings
@export var enable_anti_cheat: bool = true
@export var max_connections_per_ip: int = 1
@export var rate_limit_requests: bool = true

func save_to_file(file_path: String):
    var data = {
        "server_name": server_name,
        "port": port,
        "max_players": max_players,
        "gamemode": gamemode,
        "map": map,
        "password": password,
        "public": public,
        "auto_shutdown": auto_shutdown,
        "auto_restart": auto_restart,
        "max_uptime_hours": max_uptime_hours,
        "backup_interval_minutes": backup_interval_minutes,
        "tick_rate": tick_rate,
        "max_ping": max_ping,
        "packet_loss_threshold": packet_loss_threshold,
        "enable_anti_cheat": enable_anti_cheat,
        "max_connections_per_ip": max_connections_per_ip,
        "rate_limit_requests": rate_limit_requests
    }
    
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))
        file.close()

func load_from_file(file_path: String):
    if not FileAccess.file_exists(file_path):
        return false
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        return false
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    if json.parse(json_string) != OK:
        return false
    
    var data = json.data
    
    # Load properties
    server_name = data.get("server_name", server_name)
    port = data.get("port", port)
    max_players = data.get("max_players", max_players)
    gamemode = data.get("gamemode", gamemode)
    map = data.get("map", map)
    password = data.get("password", password)
    public = data.get("public", public)
    auto_shutdown = data.get("auto_shutdown", auto_shutdown)
    auto_restart = data.get("auto_restart", auto_restart)
    max_uptime_hours = data.get("max_uptime_hours", max_uptime_hours)
    backup_interval_minutes = data.get("backup_interval_minutes", backup_interval_minutes)
    tick_rate = data.get("tick_rate", tick_rate)
    max_ping = data.get("max_ping", max_ping)
    packet_loss_threshold = data.get("packet_loss_threshold", packet_loss_threshold)
    enable_anti_cheat = data.get("enable_anti_cheat", enable_anti_cheat)
    max_connections_per_ip = data.get("max_connections_per_ip", max_connections_per_ip)
    rate_limit_requests = data.get("rate_limit_requests", rate_limit_requests)
    
    return true
```

### 3. **Server Discovery System**
```gdscript
# server_discovery.gd
extends Node

class_name ServerDiscovery

signal server_found(server_info: Dictionary)
signal server_lost(server_address: String)
signal discovery_complete()

var discovered_servers: Dictionary = {}
var discovery_active: bool = false
var discovery_interval: float = 5.0
var discovery_timeout: float = 10.0

func start_discovery():
    if discovery_active:
        return
    
    discovery_active = true
    discovered_servers.clear()
    
    # Start discovery timer
    var timer = Timer.new()
    timer.wait_time = discovery_interval
    timer.timeout.connect(_on_discovery_tick)
    add_child(timer)
    timer.start()
    
    print("Server discovery started")

func stop_discovery():
    discovery_active = false
    
    # Stop discovery timer
    var timer = get_node_or_null("Timer")
    if timer:
        timer.queue_free()
    
    print("Server discovery stopped")

func _on_discovery_tick():
    if not discovery_active:
        return
    
    # Query known server addresses
    query_known_servers()
    
    # Broadcast discovery packets
    broadcast_discovery()

func query_known_servers():
    var known_servers = [
        "127.0.0.1:4433",
        "localhost:4433"
    ]
    
    for server_address in known_servers:
        query_server(server_address)

func query_server(server_address: String):
    var parts = server_address.split(":")
    if parts.size() != 2:
        return
    
    var ip = parts[0]
    var port = parts[1].to_int()
    
    # Create UDP socket for server query
    var socket = PacketPeerUDP.new()
    socket.connect_to_host(ip, port)
    
    # Send server info request
    var request = {
        "type": "server_info_request",
        "timestamp": Time.get_ticks_msec()
    }
    
    socket.put_packet(JSON.stringify(request).to_utf8_buffer())
    
    # Wait for response
    await get_tree().create_timer(1.0).timeout
    
    if socket.get_available_packet_count() > 0:
        var response_data = socket.get_packet()
        var response_string = response_data.get_string_from_utf8()
        
        var json = JSON.new()
        if json.parse(response_string) == OK:
            var response = json.data
            if response.has("type") and response.type == "server_info_response":
                handle_server_response(server_address, response.server_info)
    
    socket.close()

func handle_server_response(server_address: String, server_info: Dictionary):
    if not discovered_servers.has(server_address):
        discovered_servers[server_address] = server_info
        server_found.emit(server_info)
    else:
        # Update existing server info
        discovered_servers[server_address] = server_info

func broadcast_discovery():
    # Send broadcast packets to discover servers on local network
    var socket = PacketPeerUDP.new()
    socket.set_broadcast_enabled(true)
    
    var discovery_packet = {
        "type": "server_discovery",
        "timestamp": Time.get_ticks_msec()
    }
    
    socket.put_packet(JSON.stringify(discovery_packet).to_utf8_buffer())
    socket.close()

func get_discovered_servers() -> Array[Dictionary]:
    var servers = []
    for server_address in discovered_servers:
        var server_info = discovered_servers[server_address]
        server_info.server_address = server_address
        servers.append(server_info)
    
    # Sort by ping
    servers.sort_custom(func(a, b): return a.ping < b.ping)
    return servers

func ping_server(server_address: String) -> float:
    var parts = server_address.split(":")
    if parts.size() != 2:
        return -1.0
    
    var ip = parts[0]
    var port = parts[1].to_int()
    
    var start_time = Time.get_ticks_msec()
    
    var socket = PacketPeerUDP.new()
    socket.connect_to_host(ip, port)
    
    var ping_packet = {
        "type": "ping",
        "timestamp": start_time
    }
    
    socket.put_packet(JSON.stringify(ping_packet).to_utf8_buffer())
    
    # Wait for pong response
    await get_tree().create_timer(1.0).timeout
    
    if socket.get_available_packet_count() > 0:
        var response_data = socket.get_packet()
        var response_string = response_data.get_string_from_utf8()
        
        var json = JSON.new()
        if json.parse(response_string) == OK:
            var response = json.data
            if response.has("type") and response.type == "pong":
                var end_time = Time.get_ticks_msec()
                return (end_time - start_time) / 2.0  # Round trip time / 2
    
    socket.close()
    return -1.0
```

---

## 🚀 Standalone Server Release

### 1. **Server Export Configuration**
```gdscript
# server_export_config.gd
extends Node

# Server-specific export settings
var server_export_settings = {
    "application/run/main_scene": "res://scenes/dedicated_server.tscn",
    "application/config/name": "Tremble Dedicated Server",
    "application/config/description": "Dedicated server for Tremble multiplayer",
    "application/config/version": "1.0.0",
    "application/config/icon": "res://assets/server_icon.png",
    
    # Headless mode for server
    "display/window/size/viewport_width": 1,
    "display/window/size/viewport_height": 1,
    "display/window/size/resizable": false,
    "display/window/size/borderless": true,
    "display/window/size/fullscreen": false,
    "display/window/size/always_on_top": false,
    
    # Disable unnecessary features for server
    "rendering/quality/driver/driver_name": "GLES2",
    "rendering/quality/intended_usage/framebuffer_allocation": 0,
    "rendering/quality/intended_usage/framebuffer_allocation.mobile": 0,
    
    # Network settings
    "network/limits/max_queued_packets": 1024,
    "network/limits/max_packet_size": 65536,
    
    # Performance settings
    "physics/common/physics_ticks_per_second": 60,
    "physics/common/physics_jitter_fix": 0.5,
    
    # Logging
    "logging/file_logging/enable_file_logging": true,
    "logging/file_logging/log_path": "user://server.log",
    "logging/file_logging/max_log_files": 5
}

func configure_server_export():
    # Apply server-specific settings
    for setting in server_export_settings:
        ProjectSettings.set_setting(setting, server_export_settings[setting])
    
    # Save project settings
    ProjectSettings.save()
```

### 2. **Server Startup Script**
```bash
#!/bin/bash
# tremble_server.sh

# Server startup script for Linux
SERVER_DIR="/opt/tremble-server"
LOG_DIR="$SERVER_DIR/logs"
CONFIG_FILE="$SERVER_DIR/server_config.json"

# Create directories if they don't exist
mkdir -p $LOG_DIR

# Check if server is already running
if pgrep -f "tremble_server" > /dev/null; then
    echo "Tremble server is already running"
    exit 1
fi

# Start server
echo "Starting Tremble dedicated server..."
cd $SERVER_DIR

# Run server with logging
./tremble_server --config $CONFIG_FILE > $LOG_DIR/server.log 2>&1 &

# Save PID
echo $! > $SERVER_DIR/server.pid

echo "Server started with PID $(cat $SERVER_DIR/server.pid)"
```

### 3. **Windows Server Service**
```batch
@echo off
REM tremble_server.bat

set SERVER_DIR=C:\tremble-server
set LOG_DIR=%SERVER_DIR%\logs
set CONFIG_FILE=%SERVER_DIR%\server_config.json

REM Create directories
if not exist %LOG_DIR% mkdir %LOG_DIR%

REM Check if server is running
tasklist /FI "IMAGENAME eq tremble_server.exe" 2>NUL | find /I /N "tremble_server.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Tremble server is already running
    exit /b 1
)

REM Start server
echo Starting Tremble dedicated server...
cd /d %SERVER_DIR%

start /B tremble_server.exe --config %CONFIG_FILE% > %LOG_DIR%\server.log 2>&1

echo Server started
```

---

## 📋 Implementation Checklist

### Phase 1: Data Persistence
- [ ] Implement DataManager singleton
- [ ] Create data validation and backup systems
- [ ] Add player stats persistence
- [ ] Add settings persistence
- [ ] Add leaderboard persistence

### Phase 2: Server Architecture
- [ ] Create dedicated server system
- [ ] Implement server configuration
- [ ] Add server discovery system
- [ ] Create server management tools

### Phase 3: Standalone Server
- [ ] Configure server export settings
- [ ] Create server startup scripts
- [ ] Add server monitoring and logging
- [ ] Create server deployment tools

### Phase 4: Integration
- [ ] Integrate data persistence with game systems
- [ ] Add server-client communication
- [ ] Implement server administration tools
- [ ] Add server performance monitoring

### Phase 5: Advanced Features
- [ ] Add cloud save synchronization
- [ ] Implement server clustering
- [ ] Add server analytics and reporting
- [ ] Create server management dashboard

---

This comprehensive data persistence and server architecture system provides robust data management and scalable server infrastructure for Tremble, enabling both local and cloud-based multiplayer experiences. 
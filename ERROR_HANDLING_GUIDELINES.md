# 🚨 Error Handling Guidelines - Tremble

## 📋 Overview

This document outlines comprehensive error handling strategies for all systems in Tremble, ensuring robust gameplay, data integrity, and user experience.

---

## 🎯 Core Principles

### 1. **Fail Gracefully**
- Never crash the game due to recoverable errors
- Provide clear feedback to users about what went wrong
- Maintain game state consistency even during failures

### 2. **Log Everything**
- Log all errors with context (timestamp, player, action, state)
- Use different log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Include stack traces for debugging

### 3. **Recovery Strategies**
- Implement automatic retry mechanisms where appropriate
- Provide fallback options for critical systems
- Graceful degradation of features

### 4. **User Communication**
- Show user-friendly error messages
- Provide actionable solutions when possible
- Don't expose technical details to end users

---

## 🔧 System-Specific Error Handling

### 1. **Network System Errors**

#### Connection Failures
```gdscript
# network_manager.gd
func handle_connection_error(error_code: int, error_message: String):
    match error_code:
        ERR_CANT_CONNECT:
            show_user_message("Connection failed", "Server is unreachable. Check your internet connection.")
            log_error("Connection failed: %s", error_message)
        ERR_CONNECTION_ERROR:
            show_user_message("Connection lost", "Connection to server was lost. Attempting to reconnect...")
            attempt_reconnection()
        ERR_TIMEOUT:
            show_user_message("Connection timeout", "Server took too long to respond.")
            log_error("Connection timeout after %d seconds", timeout_duration)
```

#### Server Hosting Errors
```gdscript
func handle_server_startup_error(error_code: int):
    match error_code:
        ERR_ALREADY_IN_USE:
            show_user_message("Port in use", "Port %d is already in use. Try a different port.", port)
            suggest_alternative_ports()
        ERR_CANT_CREATE:
            show_user_message("Server creation failed", "Unable to create server. Check firewall settings.")
            log_critical("Server creation failed: %s", error_message)
```

### 2. **Player System Errors**

#### Health System Failures
```gdscript
# player_health.gd
func take_damage(amount: float, source = null):
    if amount < 0:
        log_warning("Negative damage received: %f from %s", amount, source)
        return
    
    if health <= 0:
        log_warning("Damage applied to already dead player")
        return
    
    # Apply damage with validation
    var old_health = health
    health = max(0.0, health - amount)
    
    # Network sync with error handling
    if multiplayer.is_server():
        if not update_health.rpc(health, armor):
            log_error("Failed to sync health update to clients")
```

#### Movement System Errors
```gdscript
# player.gd
func perform_quake_movement(delta: float):
    if not is_finite(delta) or delta <= 0:
        log_error("Invalid delta time: %f", delta)
        return
    
    # Validate velocity before applying
    if not velocity.is_finite():
        log_error("Invalid velocity detected: %s", velocity)
        velocity = Vector3.ZERO
    
    # Apply movement with bounds checking
    var new_position = global_position + velocity * delta
    if not new_position.is_finite():
        log_error("Invalid position calculated: %s", new_position)
        return
```

### 3. **Weapon System Errors**

#### Beam Gun Failures
```gdscript
# beam_gun.gd
func apply_damage_to_target(target: Node, damage: float):
    if not target:
        log_warning("Attempted to damage null target")
        return
    
    if not is_instance_valid(target):
        log_warning("Attempted to damage invalid target")
        return
    
    var health_component = find_health_component(target)
    if not health_component:
        log_warning("No health component found on target: %s", target.name)
        return
    
    # Apply damage with validation
    if damage < 0:
        log_warning("Negative damage in beam gun: %f", damage)
        return
    
    health_component.take_damage(damage, weapon_owner)
```

### 4. **Data Persistence Errors**

#### Save/Load Failures
```gdscript
# data_manager.gd
func save_player_stats(player_id: String, stats: Dictionary):
    var file = FileAccess.open("user://player_stats.json", FileAccess.WRITE)
    if not file:
        log_error("Failed to open player stats file for writing")
        show_user_message("Save failed", "Unable to save player statistics.")
        return false
    
    var json_string = JSON.stringify(stats)
    if json_string.is_empty():
        log_error("Failed to serialize player stats")
        return false
    
    file.store_string(json_string)
    file.close()
    return true

func load_player_stats(player_id: String) -> Dictionary:
    if not FileAccess.file_exists("user://player_stats.json"):
        log_info("No saved stats found for player: %s", player_id)
        return get_default_stats()
    
    var file = FileAccess.open("user://player_stats.json", FileAccess.READ)
    if not file:
        log_error("Failed to open player stats file for reading")
        return get_default_stats()
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result != OK:
        log_error("Failed to parse player stats JSON: %s", json.get_error_message())
        return get_default_stats()
    
    return json.data
```

### 5. **UI System Errors**

#### Menu Navigation Failures
```gdscript
# ui_manager.gd
func switch_to_menu(menu_name: String):
    if not menu_scenes.has(menu_name):
        log_error("Unknown menu requested: %s", menu_name)
        show_user_message("UI Error", "Menu not found. Returning to main menu.")
        switch_to_menu("main_menu")
        return
    
    var menu_scene = menu_scenes[menu_name]
    if not menu_scene:
        log_error("Menu scene is null: %s", menu_name)
        return
    
    # Attempt to instantiate menu
    var menu_instance = menu_scene.instantiate()
    if not menu_instance:
        log_error("Failed to instantiate menu: %s", menu_name)
        return
```

### 6. **Performance Monitoring Errors**

#### Metrics Collection Failures
```gdscript
# performance_monitor.gd
func record_frame_time(frame_time: float):
    if not is_finite(frame_time) or frame_time < 0:
        log_warning("Invalid frame time recorded: %f", frame_time)
        return
    
    if frame_time > 1000:  # More than 1 second
        log_warning("Extremely high frame time: %f ms", frame_time)
    
    frame_times.append(frame_time)
    
    # Maintain buffer size
    if frame_times.size() > MAX_FRAME_TIME_SAMPLES:
        frame_times.pop_front()
```

---

## 🚨 Critical Error Handling

### 1. **Game Crashes**
```gdscript
# game_manager.gd
func handle_critical_error(error_message: String, error_code: int):
    log_critical("CRITICAL ERROR: %s (Code: %d)", error_message, error_code)
    
    # Save any unsaved data
    save_emergency_data()
    
    # Show user-friendly error message
    show_critical_error_dialog(error_message)
    
    # Attempt graceful shutdown
    await get_tree().create_timer(2.0).timeout
    get_tree().quit()

func save_emergency_data():
    # Save minimal data to prevent loss
    var emergency_data = {
        "timestamp": Time.get_datetime_string_from_system(),
        "last_position": get_player_position(),
        "last_health": get_player_health()
    }
    
    var file = FileAccess.open("user://emergency_save.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(emergency_data))
        file.close()
```

### 2. **Network Disconnections**
```gdscript
# network_manager.gd
func handle_disconnection():
    log_warning("Network disconnection detected")
    
    # Attempt reconnection
    if auto_reconnect_enabled:
        start_reconnection_attempt()
    else:
        show_disconnection_dialog()
    
    # Save current game state
    save_disconnection_state()

func start_reconnection_attempt():
    reconnection_attempts += 1
    if reconnection_attempts <= MAX_RECONNECTION_ATTEMPTS:
        log_info("Attempting reconnection %d/%d", reconnection_attempts, MAX_RECONNECTION_ATTEMPTS)
        await get_tree().create_timer(RECONNECTION_DELAY).timeout
        attempt_connect_to_last_server()
    else:
        log_error("Max reconnection attempts reached")
        show_user_message("Connection failed", "Unable to reconnect to server.")
```

### 3. **Data Corruption**
```gdscript
# data_manager.gd
func validate_save_data(data: Dictionary) -> bool:
    var required_fields = ["version", "player_stats", "settings"]
    
    for field in required_fields:
        if not data.has(field):
            log_error("Missing required field in save data: %s", field)
            return false
    
    # Validate data types
    if not data.player_stats is Dictionary:
        log_error("Invalid player_stats type in save data")
        return false
    
    return true

func handle_corrupted_data():
    log_error("Corrupted save data detected")
    
    # Create backup of corrupted file
    backup_corrupted_file()
    
    # Restore from backup or create new data
    if has_valid_backup():
        restore_from_backup()
    else:
        create_new_save_data()
    
    show_user_message("Data restored", "Corrupted data was detected and has been restored.")
```

---

## 📊 Error Logging System

### 1. **Log Levels**
```gdscript
# logger.gd
enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    CRITICAL = 4
}

func log(level: LogLevel, message: String, args: Array = []):
    var timestamp = Time.get_datetime_string_from_system()
    var formatted_message = message % args
    var log_entry = "[%s] [%s] %s" % [timestamp, LogLevel.keys()[level], formatted_message]
    
    # Console output
    print(log_entry)
    
    # File logging
    write_to_log_file(log_entry)
    
    # Send to analytics if critical
    if level >= LogLevel.ERROR:
        send_error_to_analytics(log_entry)
```

### 2. **Error Reporting**
```gdscript
# error_reporter.gd
func report_error(error_type: String, error_message: String, context: Dictionary = {}):
    var error_report = {
        "type": error_type,
        "message": error_message,
        "context": context,
        "timestamp": Time.get_datetime_string_from_system(),
        "version": get_game_version(),
        "platform": OS.get_name(),
        "user_id": get_user_id()
    }
    
    # Send to error tracking service
    send_error_report(error_report)
    
    # Store locally for offline analysis
    store_error_locally(error_report)
```

---

## 🔄 Recovery Mechanisms

### 1. **Automatic Retry**
```gdscript
# retry_manager.gd
func retry_operation(operation: Callable, max_attempts: int = 3, delay: float = 1.0):
    var attempts = 0
    while attempts < max_attempts:
        attempts += 1
        
        var result = operation.call()
        if result != null:
            return result
        
        log_warning("Operation failed, attempt %d/%d", attempts, max_attempts)
        
        if attempts < max_attempts:
            await get_tree().create_timer(delay).timeout
    
    log_error("Operation failed after %d attempts", max_attempts)
    return null
```

### 2. **Fallback Systems**
```gdscript
# fallback_manager.gd
func get_server_list() -> Array:
    # Try primary server list
    var servers = fetch_primary_server_list()
    if servers.size() > 0:
        return servers
    
    # Fallback to secondary server list
    log_warning("Primary server list failed, using fallback")
    servers = fetch_fallback_server_list()
    if servers.size() > 0:
        return servers
    
    # Use local server list
    log_warning("All server lists failed, using local cache")
    return get_cached_server_list()
```

---

## 🎮 User Experience

### 1. **Error Messages**
```gdscript
# ui_error_handler.gd
func show_user_message(title: String, message: String, is_error: bool = false):
    var dialog = preload("res://scenes/ui/error_dialog.tscn").instantiate()
    dialog.setup(title, message, is_error)
    get_tree().current_scene.add_child(dialog)
    
    # Log for debugging
    if is_error:
        log_error("User shown error: %s - %s", title, message)
    else:
        log_info("User shown message: %s - %s", title, message)
```

### 2. **Loading States**
```gdscript
# loading_manager.gd
func show_loading_screen(message: String = "Loading..."):
    var loading_screen = preload("res://scenes/ui/loading_screen.tscn").instantiate()
    loading_screen.set_message(message)
    get_tree().current_scene.add_child(loading_screen)
    return loading_screen

func hide_loading_screen():
    var loading_screen = get_tree().current_scene.get_node_or_null("LoadingScreen")
    if loading_screen:
        loading_screen.queue_free()
```

---

## 🧪 Testing Error Scenarios

### 1. **Error Injection**
```gdscript
# error_testing.gd
func test_network_failures():
    # Simulate network disconnection
    simulate_network_disconnection()
    assert(connection_status == ConnectionStatus.DISCONNECTED)
    
    # Test reconnection
    await attempt_reconnection()
    assert(connection_status == ConnectionStatus.CONNECTED)

func test_data_corruption():
    # Corrupt save file
    corrupt_save_file()
    
    # Test recovery
    var data = load_player_stats("test_player")
    assert(data != null)
    assert(data.has("version"))
```

### 2. **Stress Testing**
```gdscript
# stress_test.gd
func stress_test_network():
    # Rapid connect/disconnect cycles
    for i in range(100):
        connect_to_server()
        await get_tree().create_timer(0.1).timeout
        disconnect_from_server()
        await get_tree().create_timer(0.1).timeout
    
    # Verify no memory leaks or crashes
    assert(get_memory_usage() < MAX_MEMORY_USAGE)
```

---

## 📋 Implementation Checklist

### Phase 1: Core Error Handling
- [ ] Implement logging system with levels
- [ ] Add error handling to network operations
- [ ] Add validation to player systems
- [ ] Create user-friendly error messages

### Phase 2: Recovery Systems
- [ ] Implement automatic retry mechanisms
- [ ] Add fallback systems for critical operations
- [ ] Create data corruption detection and recovery
- [ ] Add emergency save functionality

### Phase 3: Monitoring and Reporting
- [ ] Add error reporting to analytics
- [ ] Implement performance monitoring
- [ ] Create error testing framework
- [ ] Add stress testing capabilities

### Phase 4: User Experience
- [ ] Create error dialog system
- [ ] Add loading states for operations
- [ ] Implement graceful degradation
- [ ] Add user feedback for errors

---

This comprehensive error handling system ensures Tremble remains stable, user-friendly, and maintainable even when things go wrong. 
extends Node
class_name GameLogger

# Log levels
enum LogLevel {
	ERROR = 0,
	WARNING = 1,
	INFO = 2,
	DEBUG = 3
}

# Current log level (can be changed at runtime)
static var current_level: LogLevel = LogLevel.INFO

# Log categories for filtering
enum LogCategory {
	MOVEMENT,
	WEAPONS,
	MULTIPLAYER,
	HEALTH,
	GENERAL
}

# Enable/disable categories
static var enabled_categories: Array[LogCategory] = [
	LogCategory.MOVEMENT,
	LogCategory.WEAPONS,
	LogCategory.MULTIPLAYER,
	LogCategory.HEALTH,
	LogCategory.GENERAL
]

func _ready():
	# Set up as singleton
	GameLogger.current_level = LogLevel.INFO

static func log(level: LogLevel, category: LogCategory, message: String, data: Dictionary = {}):
	if level > current_level or not category in enabled_categories:
		return
	
	var level_name = LogLevel.keys()[level]
	var category_name = LogCategory.keys()[category]
	
	var log_message = "[%s][%s] %s" % [level_name, category_name, message]
	
	if data.size() > 0:
		log_message += " | Data: " + str(data)
	
	match level:
		LogLevel.ERROR:
			push_error(log_message)
		LogLevel.WARNING:
			push_warning(log_message)
		LogLevel.INFO, LogLevel.DEBUG:
			print(log_message)

# Convenience methods
static func error(category: LogCategory, message: String, data: Dictionary = {}):
	log(LogLevel.ERROR, category, message, data)

static func warning(category: LogCategory, message: String, data: Dictionary = {}):
	log(LogLevel.WARNING, category, message, data)

static func info(category: LogCategory, message: String, data: Dictionary = {}):
	log(LogLevel.INFO, category, message, data)

static func debug(category: LogCategory, message: String, data: Dictionary = {}):
	log(LogLevel.DEBUG, category, message, data)

# Set log level at runtime
static func set_log_level(level: LogLevel):
	current_level = level

# Enable/disable categories at runtime
static func enable_category(category: LogCategory):
	if not category in enabled_categories:
		enabled_categories.append(category)

static func disable_category(category: LogCategory):
	enabled_categories.erase(category) 

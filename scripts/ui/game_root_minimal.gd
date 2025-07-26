extends Control

# Game Root - Manages scene transitions between main menu and lobby

func _ready():
	print("GameRoot Minimal: _ready() called")
	
	# Start with main menu visible
	show_main_menu()
	
	print("GameRoot Minimal: _ready() completed")

func show_main_menu():
	print("GameRoot Minimal: Showing main menu")
	
	# Hide lobby screen
	var lobby_screen = get_node_or_null("LobbyScreen")
	if lobby_screen:
		lobby_screen.visible = false
	
	# Show main menu
	var main_menu = get_node_or_null("MainMenu")
	if main_menu:
		main_menu.visible = true
		print("GameRoot Minimal: Main menu shown")
	else:
		print("ERROR: GameRoot Minimal main_menu not found")

func show_lobby_screen():
	print("GameRoot Minimal: Showing lobby screen")
	
	# Hide main menu
	var main_menu = get_node_or_null("MainMenu")
	if main_menu:
		main_menu.visible = false
	
	# Show lobby screen
	var lobby_screen = get_node_or_null("LobbyScreen")
	if lobby_screen:
		lobby_screen.visible = true
		print("GameRoot Minimal: Lobby screen shown")
	else:
		print("ERROR: GameRoot Minimal lobby_screen not found")

func _process(delta):
	# Keep the scene alive
	pass 
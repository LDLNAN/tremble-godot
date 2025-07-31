extends AcceptDialog
class_name CustomConfirmationDialog

# Exported properties for easy editing in the editor
@export var dialog_title: String = "Confirm"
@export var message_text: String = "Are you sure?"
@export var cancel_button_text: String = "Cancel"
@export var confirm_button_text: String = "Confirm"

# References to UI elements
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton
@onready var confirm_button: Button = $VBoxContainer/ButtonContainer/ConfirmButton

# Callback function to call when confirmed
var on_confirm_callback: Callable
var on_cancel_callback: Callable

func _ready():
	# Set up the dialog
	title = dialog_title
	message_label.text = message_text
	cancel_button.text = cancel_button_text
	confirm_button.text = confirm_button_text
	
	# Connect button signals
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Connect dialog signals
	confirmed.connect(_on_confirm_pressed)
	canceled.connect(_on_cancel_pressed)

# Public method to configure and show the dialog
func show_dialog(title: String, message: String, cancel_text: String = "Cancel", confirm_text: String = "Confirm", on_confirm: Callable = Callable(), on_cancel: Callable = Callable()):
	# Update the dialog properties
	self.title = title
	message_label.text = message
	cancel_button.text = cancel_text
	confirm_button.text = confirm_text
	
	# Store callbacks
	on_confirm_callback = on_confirm
	on_cancel_callback = on_cancel
	
	# Show the dialog
	popup_centered()

func _on_confirm_pressed():
	# Call the confirm callback if provided
	if on_confirm_callback.is_valid():
		on_confirm_callback.call()
	
	# Hide the dialog
	hide()

func _on_cancel_pressed():
	# Call the cancel callback if provided
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	# Hide the dialog
	hide() 

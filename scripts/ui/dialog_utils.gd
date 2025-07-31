extends RefCounted
class_name DialogUtils

# Static method for easy usage of confirmation dialogs
static func show_confirmation_dialog(parent: Node, title: String, message: String, cancel_text: String = "Cancel", confirm_text: String = "Confirm", on_confirm: Callable = Callable(), on_cancel: Callable = Callable()):
	var dialog_scene = load("res://scenes/ui/confirmation_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	parent.add_child(dialog)
	dialog.show_dialog(title, message, cancel_text, confirm_text, on_confirm, on_cancel)
	return dialog 
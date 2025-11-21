extends Button

signal pressed_button(id : String)
signal delete_button_pressed(id : String)

@export var save_file_id : String

func _on_pressed() -> void:
	pressed_button.emit(save_file_id)


func _on_delete_save_pressed() -> void:
	delete_button_pressed.emit(save_file_id)

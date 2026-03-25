extends Button

signal button_clicked(button_name : String)

@export var focused_button_theme : StyleBoxFlat
@export var unfocused_button_theme : StyleBoxFlat
@export var is_focused : bool = false
@export var button_name : String

func _ready() -> void:
	text = button_name
	if is_focused:
		set_theme_to_focused()
	else:
		set_theme_to_unfocused()

func set_theme_to_focused():
	add_theme_stylebox_override("hover", focused_button_theme)
	add_theme_stylebox_override("pressed", focused_button_theme)
	add_theme_stylebox_override("normal", focused_button_theme)

func set_theme_to_unfocused():
	add_theme_stylebox_override("hover", unfocused_button_theme)
	add_theme_stylebox_override("pressed", unfocused_button_theme)
	add_theme_stylebox_override("normal", unfocused_button_theme)


func _on_pressed() -> void:
	button_clicked.emit(button_name)

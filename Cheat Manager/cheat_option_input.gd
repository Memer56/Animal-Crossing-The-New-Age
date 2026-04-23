extends Control

@export var cheat_name : String
@export var placeholder_text : String
@onready var label: Label = $VBoxContainer/HBoxContainer/Label
@onready var line_edit: LineEdit = $VBoxContainer/HBoxContainer/LineEdit

func _ready() -> void:
	label.text = cheat_name
	line_edit.placeholder_text = placeholder_text


func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text_is_integers(new_text):
		CheatManager.submit_line_input(new_text, cheat_name)
	elif new_text is String:
		CheatManager.submit_line_input(new_text, cheat_name)

func new_text_is_integers(input_text : String) -> bool:
	var converted_text : int = int(input_text)
	if converted_text:
		return true
	return false

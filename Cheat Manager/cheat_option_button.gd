extends Control

@export var cheat_name : String
@export var default_button_name : String
@onready var label: Label = $VBoxContainer/HBoxContainer/Label
@onready var button: Button = $VBoxContainer/HBoxContainer/Button

func _ready() -> void:
	label.text = cheat_name
	button.text = default_button_name


func _on_button_pressed() -> void:
	CheatManager.submit_button_press(cheat_name)

extends Control

signal temp_confirm_signal()

@export var text : String
@export var is_for_placing_object : bool = false
@onready var label: Label = $Panel/Label

func _ready() -> void:
	label.text = text


func _on_confirm_pressed() -> void:
	if is_for_placing_object:
		BuildManager.spawn_object()
		queue_free()
	else:
		temp_confirm_signal.emit()


func _on_cancel_pressed() -> void:
	queue_free()

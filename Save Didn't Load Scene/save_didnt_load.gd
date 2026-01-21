extends Node3D

@onready var camera_3d: Camera3D = $Camera3D

func _ready() -> void:
	camera_3d.current = true
	send_error_text()

func send_error_text():
	var text = [
		"Ohh no...",
		"Your game save data may be [color=red]corrupt[/color]...",
		"Get your loving [color=gold]Hayden[/color] to fix it."
	]
	EventBus.display_speech_bubble.emit(text, "Tom Nook")

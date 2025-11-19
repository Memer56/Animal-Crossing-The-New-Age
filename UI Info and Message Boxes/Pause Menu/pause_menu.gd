extends Control


func _on_button_pressed() -> void:
	EventBus.save_game_data.emit()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Pause"):
		toggle_game_pause()
		toggle_self()

func toggle_game_pause():
	if get_tree().paused == true:
		get_tree().paused = false
	elif get_tree().paused == false:
		get_tree().paused = true

func toggle_self():
	if visible:
		visible = false
	else:
		visible = true

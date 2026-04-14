extends Control

@onready var resume: Button = $Panel/VBoxContainer/Resume


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
	
	resume.grab_focus()


func _on_resume_pressed() -> void:
	toggle_game_pause()
	toggle_self()


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_save_pressed() -> void:
	EventBus.save_game_data.emit()
	toggle_self()
	EventBus.display_speech_bubble.emit(["Game saved [color=green]successfully[/color]"], "Yayy", [], null)
	toggle_game_pause()


func _on_save_and_quit_pressed() -> void:
	EventBus.is_returning_to_main_menu = true
	EventBus.save_game_data.emit()
	FadeCanvasLayer.trigger_scene_change_fade(true)
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file.bind("res://UI Info and Message Boxes/Main Menu/main_menu.tscn").call_deferred()

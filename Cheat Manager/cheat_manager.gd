extends Node

signal remove_ui

var cheat_menu_displayed : bool = true

func submit_line_input(new_text : String, cheat_name : String):
	match cheat_name:
		"Set Money":
			EventBus.savings_balance = int(new_text)
			EventBus.display_speech_bubble.emit(["Successfully set balance to [color=green]" + new_text + "[/color]."], "Info", [], null)
		"Add Money":
			EventBus.savings_balance += int(new_text)
			EventBus.display_speech_bubble.emit(["Successfully added [color=green]" + new_text + "[/color] to balance."], "Info", [], null)
		"Set Time":
			set_time(new_text)

func set_time(text : String):
	var new_text = text.to_lower()
	if new_text.contains("day"):
		EventBus.world_time = 0.3
	
	if new_text.contains("night"):
		EventBus.world_time = 1.0

func submit_button_press(cheat_name : String):
	match cheat_name:
		"Free Craft":
			pass

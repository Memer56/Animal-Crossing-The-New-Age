extends Control

@onready var player_creation_h_box: HBoxContainer = $BG/Panel/Panel/PlayerCreationHBox
@onready var island_selection_v_box: VBoxContainer = $BG/Panel/Panel/IslandSelectionVBox
@export var tab_buttons : Array[Button]

var player_text_tutorial_is_done : bool = false
var player_name : String
var skin_colour : Color
var hair_colour : Color

func _ready() -> void:
	EventBus.is_in_overworld = true
	#display_intro_text()
	display_correct_container("PlayerCreation")
	tab_buttons[0].button_pressed = true ## Player creation button appears as pressed

func display_intro_text():
	var text : Array = [
		"Welcome to the selection screen!",
		"On this screen you will be able to enter your name and select your skin and hair colour...",
		"you can also select which island you wish to play on but...",
		"remember, once this island is selected you cannot change it!",
		"Go ahead and choose your player details and island and have fun!"
	]
	EventBus.display_speech_bubble.emit(text, "Info", [], null)

func _on_tab_option_pressed(source: BaseButton) -> void:
	for button in tab_buttons:
		if button.name == source.name:
			button.button_pressed = true
			display_correct_container(button.name)
		else:
			button.button_pressed = false

func display_correct_container(button_name : String):
	match button_name:
		"PlayerCreation":
			player_creation_h_box.show()
			island_selection_v_box.hide()
		"IslandSelection":
			player_creation_h_box.hide()
			island_selection_v_box.show()


func _on_line_edit_text_submitted(new_text: String) -> void:
	player_name = new_text

func _on_line_edit_text_changed(new_text: String) -> void:
	player_name = new_text

func _on_skin_color_changed(color: Color) -> void:
	skin_colour = color


func _on_hair_color_changed(color: Color) -> void:
	hair_colour = color


func _on_confirm_button_pressed() -> void:
	EventBus.player_customisations.append(player_name)
	EventBus.player_customisations.append(skin_colour)
	EventBus.player_customisations.append(hair_colour)
	
	if !EventBus.selected_island_info.is_empty():
		EventBus.next_scene = "res://Main World/main.tscn"
		get_tree().change_scene_to_file("res://UI Info and Message Boxes/Load Screen/load_screen.tscn")

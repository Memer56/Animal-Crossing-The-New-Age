extends Control

const SAVE_SLOT = preload("uid://d4dbaiqcga11c")
const CONFIRM_MESSAGE = preload("uid://btn78ebu7dnjd")

@onready var press_any_button: RichTextLabel = $BG/PressAnyButton
@onready var main_buttons: VBoxContainer = $BG/MainButtons
@onready var save_slots: VBoxContainer = $BG/Container/ScrollContainer/MarginContainer/SaveSlots
@onready var container: Control = $BG/Container
@onready var bg: Panel = $BG

var save : SaveGame
var save_json_ids : SaveGame
var any_button_was_pressed : bool = false
var save_date_time : String
var save_slots_already_loaded : bool = false
var file_id_for_deletion : String
var confirm_message
#[pulse freq=1.0 color=#ffffff40 ease=-2.0]Press any button[/pulse]


func _ready() -> void:
	get_tree().paused = false
	any_button_was_pressed = false
	if EventBus.is_returning_to_main_menu:
		EventBus.is_returning_to_main_menu = false
		FadeCanvasLayer.trigger_scene_change_fade(false)

func _input(event: InputEvent) -> void:
	if Input.is_anything_pressed() and !any_button_was_pressed:
		main_buttons.visible = true
		fade_out_label()
		fade_in_main_buttons()
		any_button_was_pressed = true

func fade_out_label():
	var tween = get_tree().create_tween()
	tween.tween_property(press_any_button, "modulate:a", 0, 1.0)

func fade_in_main_buttons():
	var tween = get_tree().create_tween()
	tween.tween_property(main_buttons, "modulate:a", 1, 1.0)
	for button in main_buttons.get_children():
		button.disabled = false


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://UI Info and Message Boxes/Load Screen/load_screen.tscn")


func _on_load_game_pressed() -> void:
	display_and_init_save_slots()
	toggle_main_buttons_and_save_slots()


func _on_quit_pressed() -> void:
	get_tree().quit()

func display_and_init_save_slots():
	var save_json_ids = SaveGame.new()
	if !save_slots_already_loaded:
		save_slots_already_loaded = true
		# Delete any nodes under save_slots
		var previous_save_slots =  save_slots.get_children()
		if previous_save_slots:
			for node in previous_save_slots:
				node.queue_free()
		
		if save_json_ids.json_file_exists():
			var data = save_json_ids.read_json_file()
			for index in data.size():
				var new_slot = SAVE_SLOT.instantiate()
				save_slots.add_child(new_slot)
				new_slot.text = "Save " + str(index + 1) + load_save_date_time(data[index])
				new_slot.save_file_id = data[index]
				new_slot.pressed_button.connect(_on_save_button_pressed)
				new_slot.delete_button_pressed.connect(_on_delete_button_pressed)

func toggle_main_buttons_and_save_slots():
	if main_buttons.visible:
		main_buttons.hide()
		container.show()
	else:
		main_buttons.show()
		container.hide()

func load_save_date_time(id : String):
	save = SaveGame.load_savegame_data(id)
	var time = save.this_save_date
	return "          " + time

func _on_save_button_pressed(id : String):
	EventBus.game_is_new_save = false
	EventBus.current_save_file_id = id
	get_tree().change_scene_to_file("res://UI Info and Message Boxes/Load Screen/load_screen.tscn")

func _on_delete_button_pressed(id : String):
	file_id_for_deletion = id
	confirm_message = CONFIRM_MESSAGE.instantiate()
	confirm_message.text = "Do you want to delete this save?"
	add_child(confirm_message)
	if !confirm_message.temp_confirm_signal.is_connected(_temp_confirm_sent):
		confirm_message.temp_confirm_signal.connect(_temp_confirm_sent)

func _temp_confirm_sent():
	# Triggered by confirm_message signal
	confirm_message.queue_free()
	delete_file()

func delete_file():
	var json_file = SaveGame.new()
	save = SaveGame.delete_savegame(file_id_for_deletion)
	json_file.update_json_file(file_id_for_deletion, true)
	save_slots_already_loaded = false
	display_and_init_save_slots()

func _on_back_pressed() -> void:
	toggle_main_buttons_and_save_slots()

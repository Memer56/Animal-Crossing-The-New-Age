extends Control

const SAVE_GAME_PATH = "user://Game Data/"

const SAVE_SLOT = preload("uid://d4dbaiqcga11c")
const CONFIRM_MESSAGE = preload("uid://btn78ebu7dnjd")

@onready var press_any_button: RichTextLabel = $BG/PressAnyButton
@onready var main_buttons: VBoxContainer = $BG/MainButtons
@onready var save_slots: VBoxContainer = $BG/Container/ScrollContainer/MarginContainer/SaveSlots
@onready var container: Control = $BG/Container
@onready var bg: Panel = $BG
@onready var game_version_label: Label = $BG/GameVersionLabel
@onready var new_game: Button = $BG/MainButtons/NewGame
@onready var fade_canvas_layer: CanvasLayer = $FadeCanvasLayer

var save : SaveGame
var save_json_ids : SaveGame
var any_button_was_pressed : bool = false
var save_date_time : String
var save_slots_already_loaded : bool = false
var file_id_for_deletion : String
var confirm_message
var new_game_button_has_grabbed_focus : bool = false
#[pulse freq=1.0 color=#ffffff40 ease=-2.0]Press any button[/pulse]


func _ready() -> void:
	get_tree().paused = false
	any_button_was_pressed = false
	EventBus.player_can_leave_nav_mesh = true
	game_version_label.text = "Game Version: " + ProjectSettings.get_setting("application/config/version")
	open_game_data_folder(SAVE_GAME_PATH)
	if EventBus.is_returning_to_main_menu:
		EventBus.is_returning_to_main_menu = false
		fade_canvas_layer.trigger_scene_change_fade(false)

func _process(_delta: float) -> void:
	if Input.get_connected_joypads() and !new_game_button_has_grabbed_focus:
		print("Controller detected, grabbing focus")
		new_game.grab_focus.call_deferred()
		await get_tree().create_timer(0.5).timeout
		new_game_button_has_grabbed_focus = true

func _input(_event: InputEvent) -> void:
	if Input.is_anything_pressed() and !any_button_was_pressed:
		main_buttons.visible = true
		fade_out_label()
		fade_in_main_buttons()
		await get_tree().create_timer(0.2).timeout
		any_button_was_pressed = true

func fade_out_label():
	var tween = get_tree().create_tween()
	tween.tween_property(press_any_button, "modulate:a", 0, 1.0)

func fade_in_main_buttons():
	var tween = get_tree().create_tween()
	tween.tween_property(main_buttons, "modulate:a", 1, 1.0)
	#new_game.pressed.connect(_on_new_game_pressed)
	for button in main_buttons.get_children():
		button.disabled = false


func _on_new_game_pressed() -> void:
	if any_button_was_pressed:
		EventBus.is_in_overworld = true
		EventBus.game_is_new_save = true
		EventBus.next_scene = "res://Main World/main.tscn"
		get_tree().change_scene_to_file("res://UI Info and Message Boxes/Load Screen/load_screen.tscn")


func _on_load_game_pressed() -> void:
	if any_button_was_pressed:
		display_and_init_save_slots()
		toggle_main_buttons_and_save_slots()


func _on_quit_pressed() -> void:
	if any_button_was_pressed:
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
		
		if EventBus.found_save_file_ids:
			var data = EventBus.found_save_file_ids
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
	var time
	if SaveGame.save_exists(id):
		save = SaveGame.load_savegame_data(id)
		time = " " + save.this_save_date
	else:
		time = "       File cannot load!"
	
	return time

func _on_save_button_pressed(id : String):
	EventBus.game_is_new_save = false
	EventBus.is_in_overworld = true
	EventBus.current_save_file_id = id
	EventBus.next_scene = "res://Main World/main.tscn"
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
	save_slots_already_loaded = false
	EventBus.found_save_file_ids.erase(file_id_for_deletion)
	display_and_init_save_slots()

func _on_back_pressed() -> void:
	toggle_main_buttons_and_save_slots()

func open_game_data_folder(path):
	# Search folder
	# Add save id's to array
	# Know what save slot is what based on array order
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				var file_without_extension = file_name.get_basename()
				var game_file_id = file_without_extension.split(" ")
				var id = game_file_id.slice(1, game_file_id.size())
				var packed_id_array_value = id.get(0) #Removes it from an array ["version_num"] --> "version_num
				#print("Found file: " , game_version)
				if !EventBus.found_save_file_ids.has(packed_id_array_value) and packed_id_array_value:
					EventBus.found_save_file_ids.append(packed_id_array_value)
					print("Found file id's array : ", EventBus.found_save_file_ids)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

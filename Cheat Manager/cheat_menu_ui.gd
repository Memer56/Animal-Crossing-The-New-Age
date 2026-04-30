extends Control

const CRAFTING_OPTION_DISPLAY_BUTTON = preload("uid://c5afvfdm0pit6")

@export var options_list_buttons : Array[Button]
@export var crafting_option_button_data : Array[Array]
@onready var general_cheats_container: VBoxContainer = $BG/GeneralCheatsContainer
@onready var give_items_container: VBoxContainer = $BG/GiveItemsContainer
@onready var search_bar: LineEdit = $BG/GiveItemsContainer/SearchBar
@onready var general_cheats: Button = $BG/OptionsBG/OptionsList/GeneralCheats
@onready var selected_item_texture: TextureRect = $BG/GiveItemsContainer/HBoxContainer/Panel/SelectedItemTexture
@onready var grid_container: GridContainer = $BG/GiveItemsContainer/ScrollContainer/GridContainer

var mouse_is_on_search_bar : bool = false
var current_slot_data : SlotData

func _ready() -> void:
	CheatManager.remove_ui.connect(remove_self)
	general_cheats.button_pressed = true
	fill_button_data_array()

func fill_button_data_array():
	for child in grid_container.get_children():
		var data : Array = [child.texture, child.item_name, child.result_item, child.display_name]
		crafting_option_button_data.append(data)

func _on_option_pressed(source: BaseButton) -> void:
	for button in options_list_buttons:
		if button.name == source.name:
			button.button_pressed = true
			display_correct_container(button.name)
		else:
			button.button_pressed = false

func display_correct_container(button_name : String):
	match button_name:
		"GeneralCheats":
			general_cheats_container.show()
			give_items_container.hide()
		"GiveItems":
			general_cheats_container.hide()
			give_items_container.show()

func remove_self():
	queue_free()


func _on_search_bar_focus_exited() -> void:
	search_bar.release_focus()

func _on_search_bar_mouse_entered() -> void:
	mouse_is_on_search_bar = true


func _on_search_bar_mouse_exited() -> void:
	mouse_is_on_search_bar = false


func _on_search_bar_text_submitted(new_text: String) -> void:
	var text : String = new_text.to_lower()
	clear_crafting_options_buttons_from_scene()
	
	if text == "":
		for data in crafting_option_button_data:
			spawn_crafting_display_button(data)
	else:

		for data in crafting_option_button_data:
			var item_name : String = data[1].to_lower()
			if item_name.contains(text):
				spawn_crafting_display_button(data)

func spawn_crafting_display_button(data : Array):
	var new_button = CRAFTING_OPTION_DISPLAY_BUTTON.instantiate()
	new_button.texture = data[0]
	new_button.item_name = data[1]
	new_button.result_item = data[2]
	new_button.display_name = data[3]
	grid_container.add_child(new_button)
	new_button.connect("send_data", _on_crafting_option_display_button_send_data)

func clear_crafting_options_buttons_from_scene():
	for child in grid_container.get_children():
		child.queue_free()

func _on_gui_input(event: InputEvent) -> void:
	# For root control node
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if !mouse_is_on_search_bar:
				search_bar.release_focus()

func _on_bg_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if !mouse_is_on_search_bar:
				search_bar.release_focus()

func _on_crafting_option_display_button_send_data(item_texture: AtlasTexture, slot_data: SlotData) -> void:
	selected_item_texture.texture = item_texture
	current_slot_data = slot_data


func _on_give_item_button_pressed() -> void:
	if current_slot_data:
		if EventBus.player.hotbar_inventory_data.add_to_inventory(current_slot_data):
			return
		elif EventBus.player.inventory_data.add_to_inventory(current_slot_data):
			return
		else:
			EventBus.display_speech_bubble.emit(["Inventory is [color=red]full[/color]."], "Info", [], null)

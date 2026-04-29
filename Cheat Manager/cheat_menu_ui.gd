extends Control

const CRAFTING_OPTION_DISPLAY_BUTTON = preload("uid://c5afvfdm0pit6")

@export var options_list_buttons : Array[Button]
@onready var general_cheats_container: VBoxContainer = $BG/GeneralCheatsContainer
@onready var give_items_container: VBoxContainer = $BG/GiveItemsContainer
@onready var search_bar: LineEdit = $BG/GiveItemsContainer/SearchBar
@onready var general_cheats: Button = $BG/OptionsBG/OptionsList/GeneralCheats
@onready var selected_item_texture: TextureRect = $BG/GiveItemsContainer/HBoxContainer/Panel/SelectedItemTexture

var mouse_is_on_search_bar : bool = false
var current_slot_data : SlotData

func _ready() -> void:
	CheatManager.remove_ui.connect(remove_self)
	general_cheats.button_pressed = true

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
	pass # Replace with function body.


func _on_gui_input(event: InputEvent) -> void:
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

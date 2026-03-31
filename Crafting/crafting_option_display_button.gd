extends Control

signal send_crafting_data(crafting_requirements : Dictionary, button_texture, output_qty, result_item, button)

@export var texture : AtlasTexture
@export var item_name : String
@onready var texture_rect: TextureRect = $Panel/TextureRect
@export var crafting_requirements : Dictionary[String, Array]
@export var output_quantity : int
@export var result_item : SlotData
@export var unfocused_button_theme : StyleBoxFlat
@export var focused_button_theme : StyleBoxFlat
##Realates to which catagory this button belongs to e.g Furniture(index 2), be default all buttons will show in ALL,
## therefor, index 0 is not used
@export var category_index : int
@onready var panel: Panel = $Panel

func _ready() -> void:
	if texture:
		texture_rect.texture = texture


func _on_panel_mouse_entered() -> void:
	panel.add_theme_stylebox_override("panel", focused_button_theme)


func _on_panel_mouse_exited() -> void:
	panel.add_theme_stylebox_override("panel", unfocused_button_theme)


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MASK_LEFT:
			send_crafting_data.emit(crafting_requirements, texture, output_quantity, result_item, self)

func resend_crafting_data():
	send_crafting_data.emit(crafting_requirements, texture, output_quantity, result_item, self)

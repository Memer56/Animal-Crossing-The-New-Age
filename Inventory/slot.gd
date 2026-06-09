extends PanelContainer
class_name SlotIndex

signal slot_clicked(index : int, button : int)

@onready var texture_rect = $MarginContainer/TextureRect
@onready var quantity_label = $MarginContainer/TextureRect/QuantityLabel
@onready var highlight: Panel = $Highlight
@export var index_value : int
@onready var hot_bar_highlight: TextureRect = $HotBarHighlight

var is_being_highlighted : bool = false
var slot_slot_data : SlotData


func set_slot_data(slot_data : SlotData) -> void:
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.texture
	tooltip_text = "%s\n%s" % [item_data.name, item_data.description]
	slot_slot_data = slot_data
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()

func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
	

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_A and event.is_released() and is_being_highlighted:
			var joy_click = InputEventMouseButton.new()
			joy_click.button_index = MOUSE_BUTTON_LEFT
			joy_click.position = get_viewport().get_mouse_position()
			joy_click.pressed = true
			slot_clicked.emit(get_index(), event.button_index)
	
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_X and event.is_released() and is_being_highlighted:
			var joy_click = InputEventMouseButton.new()
			joy_click.button_index = MOUSE_BUTTON_LEFT
			joy_click.position = get_viewport().get_mouse_position()
			joy_click.pressed = true
			slot_clicked.emit(get_index(), (event.button_index + 1))

func _on_mouse_entered() -> void:
	highlight.visible = true
	is_being_highlighted = true


func _on_mouse_exited() -> void:
	highlight.visible = false
	is_being_highlighted = false

func toggle_hotbar_highlight(value : bool):
	hot_bar_highlight.visible = value

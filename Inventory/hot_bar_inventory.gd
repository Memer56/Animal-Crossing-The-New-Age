extends PanelContainer

signal hot_bar_use(index: int)
signal send_held_slot_data(slot_data : SlotData)

const Slot = preload("res://Inventory/slot.tscn")

@onready var h_box_container = $MarginContainer/HBoxContainer
@onready var item_slot_highlight: Sprite2D = $ItemSlotHighlight

var array : Array
var slot_array : Array
var current_position = 0
var game_start_up : bool = true
var item : SlotData

func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	sort_slot_array()

func sort_slot_array():
	if array:
		for element in array:
			if element != null:
				slot_array.append(element)
		
		if game_start_up:
			item_slot_highlight.global_position = slot_array[0].global_position
			current_position = current_position % slot_array.size()
			item = EventBus.player.hot_bar_inventory_data.return_slot_data_by_index(current_position)
			EventBus.held_item_slot_data = item
			game_start_up = false

func _unhandled_key_input(event):
	if not visible or not event.is_pressed():
		return
	
	if range(KEY_1, KEY_7).has(event.keycode):
		hot_bar_use.emit(event.keycode - KEY_1)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("MouseWheelDown"):
		current_position = (current_position + 1) % slot_array.size()
		item_slot_highlight.global_position = slot_array[current_position].global_position
		item = EventBus.player.hot_bar_inventory_data.return_slot_data_by_index(current_position)
		EventBus.held_item_slot_data = item
		send_set_hand_item_signal(item)
	if Input.is_action_just_released("MouseWheelUp"):
		current_position = (current_position - 1) % slot_array.size()
		item_slot_highlight.global_position = slot_array[current_position].global_position
		item = EventBus.player.hot_bar_inventory_data.return_slot_data_by_index(current_position)
		EventBus.held_item_slot_data = item
		send_set_hand_item_signal(item)

func send_set_hand_item_signal(_item : SlotData):
	send_held_slot_data.emit(_item)

func set_held_item():
	# Called when items are clicked and dragged into place
	item = EventBus.player.hot_bar_inventory_data.return_slot_data_by_index(current_position)
	EventBus.held_item_slot_data = item
	send_set_hand_item_signal(item)

func set_inventory_data(inventory_data : InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)


func populate_hot_bar(inventory_data : InventoryData) -> void:
	array.clear()
	slot_array.clear()
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas: #.slice(0, 6) this was used here
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		array.append(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)
	
	if !game_start_up:
		sort_slot_array()
		set_held_item()

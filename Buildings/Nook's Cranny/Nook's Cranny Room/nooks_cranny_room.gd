extends Node

const SHOP_INTERACT_OBJECT = preload("uid://47lfgiilmfuq")


@export var interact_spawn_points : Array[Marker3D]
@export var items : Dictionary[String, PackedScene]

var selected_items : Array

func _ready() -> void:
	if EventBus.nooks_cranny_has_set_items:
		spawn_set_interact_objects()
	else:
		select_items_to_display()

func select_items_to_display():
	while selected_items.size() < interact_spawn_points.size():
		var new_item = items.keys().pick_random()
		if !selected_items.has(new_item):
			selected_items.append(new_item)
	
	spawn_new_interact_objects()

func spawn_new_interact_objects():
	for index in interact_spawn_points.size():
		var new_interact_object = SHOP_INTERACT_OBJECT.instantiate()
		interact_spawn_points[index].add_child(new_interact_object)
		
		var new_item = items[selected_items[index]].instantiate()
		new_interact_object.add_child(new_item)
		new_item.add_to_group("DisplayItem")
		new_item.disable_interaction = true
		
		var new_slot_data = SlotData.new()
		new_slot_data = new_item.self_slot_data
		new_interact_object.item_slot_data = new_slot_data
		new_interact_object.item_value = new_slot_data.item_data.price
		
	EventBus.nooks_cranny_has_set_items = true

func spawn_set_interact_objects():
	for index in interact_spawn_points.size():
		var saved_display_items_keys = EventBus.nooks_cranny_displays.keys()
		var new_interact_object = SHOP_INTERACT_OBJECT.instantiate()
		interact_spawn_points[index].add_child(new_interact_object)
		selected_items = saved_display_items_keys
		
		var new_item = items[saved_display_items_keys[index]].instantiate()
		new_interact_object.add_child(new_item)
		new_item.add_to_group("DisplayItem")
		new_item.disable_interaction = true
		
		var item_price : int = EventBus.nooks_cranny_displays[saved_display_items_keys[index]][0]
		var item_slot_data : SlotData = EventBus.nooks_cranny_displays[saved_display_items_keys[index]][1]
		var was_item_sold : bool = EventBus.nooks_cranny_displays[saved_display_items_keys[index]][2]
		new_interact_object.set_information(item_price, item_slot_data, was_item_sold)

func _on_save_display_info_body_entered(body: Node3D) -> void:
	if body.get_collision_layer() == 1:
		
		if EventBus.item_was_bought_during_visit or selected_items:
			EventBus.nooks_cranny_displays.clear()
			var displays = get_tree().get_nodes_in_group("ShopObject")
			for index in displays.size():
				var item_price = displays[index].item_value
				var item_slot_data = SlotData.new()
				item_slot_data = displays[index].item_slot_data
				var item_has_been_sold = displays[index].has_been_sold
				
				EventBus.nooks_cranny_displays[selected_items[index]] = [item_price, item_slot_data, item_has_been_sold]

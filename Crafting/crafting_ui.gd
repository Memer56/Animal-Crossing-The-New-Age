extends Control

const CRAFTING_REQUIREMENT_INFO = preload("res://Crafting/crafting_requirement_info.tscn")


@onready var required_items_list: VBoxContainer = $BG/Panel/CraftingRequirements/Panel/RequiredItemsList
@onready var item_name_label: Label = $BG/Panel/CraftingRequirements/ItemName
@onready var all_tab_button: TextureRect = $BG/Panel/TabButtons/AllTabButton
@onready var tool_tab_button: TextureRect = $BG/Panel/TabButtons/ToolTabButton
@onready var furniture_tab_button: TextureRect = $BG/Panel/TabButtons/FurnitureTabButton
@onready var wallpaper_and_flooring_tab_button: TextureRect = $BG/Panel/TabButtons/WallpaperAndFlooringTabButton
@onready var craft: Button = $BG/Panel/CraftingRequirements/Panel/Craft
@onready var quantity_label: Label = $BG/Panel/CraftingRequirements/Panel/QuantityLabel


var tab_buttons : Array
var item_name : String
var hot_bar_item_data_array : Dictionary
var inventory_item_data_array : Dictionary
var crafting_requirement_item_names : Array
var crafting_requirement_item_quantities : Array
var crafting_requirement_item_textures : Array
var listed_crafting_requirements : Dictionary
var output_item : SlotData
var button_that_was_fired
var can_begin_process : bool = true
var player: CharacterBody3D
var player_inventory
var player_hotbar
var requirement_met_inventory : bool = false
var requirement_met_hot_bar : bool = false
var quantity_multiplier : int = 1
var normal_button_colour : Color = Color("a38551")
var hover_and_selected_button_colour : Color = Color("ffa21dff")
var tab_button_that_was_pressed : TextureRect


func _ready() -> void:
	# Allows for EventBus.player to be set in Player script
	await get_tree().create_timer(0.1).timeout
	EventBus.toggle_crafting_ui.connect(toggle_self_ui)
	player = EventBus.player
	player_inventory = EventBus.player.inventory_data
	player_hotbar = EventBus.player.hotbar_inventory_data
	for buttons in get_tree().get_nodes_in_group("TabButton"):
		tab_buttons.append(buttons)


func toggle_self_ui():
	if visible:
		reset_everything()
		visible = false
	else:
		visible = true

func _on_crafting_option_display_button_send_crafting_data(crafting_requirements: Dictionary, button_texture: Variant, output_qty: Variant, result_item: Variant, button: Variant) -> void:
		reset_everything()
		
		#quantity_label.text = str(output_qty * quantity_multiplier)
		output_item = result_item
		output_item.quantity = (output_qty * quantity_multiplier)
		listed_crafting_requirements = crafting_requirements
		button_that_was_fired = button
		item_name_label.text = result_item.item_data.name
		#print(crafting_requirements)
		# Grab needed info, this is pointless now
		for key in crafting_requirements:
			crafting_requirement_item_names.append(key)
			crafting_requirement_item_quantities.append(crafting_requirements[key][0])
			crafting_requirement_item_textures.append(crafting_requirements[key][1])
		
		# check inventories for items, index 0 = quantity, index 1 = index and so on....
		# check inventory
		for key in crafting_requirement_item_names:
			for index in player_inventory.slot_datas.size():
				var items = player_inventory.locate_item_in_inventory_by_name(key)
				if items:
					inventory_item_data_array[key] = items
					break
		
		# check hotbar inventory
		for key in crafting_requirement_item_names:
			for index in player_hotbar.slot_datas.size():
				var items = player.hotbar_inventory_data.locate_item_in_inventory_by_name(key)
				if items:
					hot_bar_item_data_array[key] = items
					break

		can_craft(crafting_requirements, player_inventory, player_hotbar)

func can_craft(crafting_requirements, inventory, hotbar_inventory):
	var can_craft_item : bool
	
	var quantity


	for item in crafting_requirements:
		var required_quantity = crafting_requirements[item][0]
		var total_quantity = get_total_quantity(item, inventory, hotbar_inventory)
		
		required_quantity *= quantity_multiplier
		
		if total_quantity >= required_quantity:
			can_craft_item = true
			#print("Item: %s, Required: %d, Found: %d" % [item, required_quantity, total_quantity])
		else:
			#print("Item: %s, Required: %d, Found: %d" % [item, required_quantity, total_quantity])
			can_craft_item = false
		spawn_and_load_requirement_info_button(total_quantity, required_quantity, crafting_requirements[item][1], can_craft_item)

	if can_craft_item:
		#print("You have all the required items for crafting.")
		craft.disabled = false
	else:
		#print("You don't have enough items to craft.")
		craft.disabled = true

func get_total_quantity(item_name, inventory, hotbar_inventory) -> int:
	var total_quantity = 0
	var inventory_quantity = 0
	var hot_bar_quantity = 0
	
	if player_inventory.is_item_in_inventory_return_bool(item_name):
		inventory_quantity = sum_of_array_even(inventory_item_data_array[item_name])
	
	if player_hotbar.is_item_in_inventory_return_bool(item_name):
		hot_bar_quantity = sum_of_array_even(hot_bar_item_data_array[item_name])
	
	total_quantity = inventory_quantity + hot_bar_quantity
	return total_quantity


func spawn_and_load_requirement_info_button(_known_count : int, _required_count_value : int, _texture, can_be_crafted : bool):
	var info = CRAFTING_REQUIREMENT_INFO.instantiate()
	required_items_list.add_child(info)
	info.load_data(_known_count, _required_count_value, _texture, can_be_crafted)


func sum_of_array_even(array : Array) -> int:
	var sum : int
	for i in array.size():
		if i % 2 == 0:
			sum += array[i]
	return sum

func return_array_values_at_odd_indexes(array : Array) -> Array:
	var return_array : Array
	for i in range(array.size()):
		if i % 2 != 0:
			return_array.append(array[i])
	return return_array

func return_array_values_at_even_indexes(array : Array) -> Array:
	var return_array : Array
	for i in range(array.size()):
		if i % 2 == 0:
			return_array.append(array[i])
	return return_array

func sum_of_all_array(array : Array) -> int:
	var sum : int
	for i in range(array.size()):
		sum += array[i]
	return sum

func return_true(boolean) -> bool:
	return boolean == true

func reset_everything():
	hot_bar_item_data_array.clear()
	inventory_item_data_array.clear()
	crafting_requirement_item_names.clear()
	crafting_requirement_item_quantities.clear()
	crafting_requirement_item_textures.clear()
	craft.disabled = true
	#output_count.hide()
	if can_begin_process:
		can_begin_process = false
		var child_node = required_items_list.get_children()
		if child_node:
			for child in child_node:
				child.queue_free()
	can_begin_process = true


func _on_craft_pressed() -> void:
	# find and remove items from hotbar
	var num_of_items_removed = 0
	var total_qty : int
	find_and_remove_items_from_hotbar(total_qty, num_of_items_removed)
	button_that_was_fired.resend_crafting_data()
	give_player_crafted_item()
	output_item = null

func find_and_remove_items_from_hotbar(total_qty, num_of_items_removed):
	for item in listed_crafting_requirements:
		var hot_bar_item = player_hotbar.is_item_in_inventory_return_bool(item)
		if hot_bar_item:
			var indexes = return_array_values_at_odd_indexes(hot_bar_item_data_array[item])
			var qty = listed_crafting_requirements[item][0]
			total_qty = qty
			var qty_of_each_item_array = return_array_values_at_even_indexes(hot_bar_item_data_array[item])
			var total_qty_of_item_array = sum_of_all_array(qty_of_each_item_array)
			var n = 0
			var spent_item_stacks : Array
			for i in indexes.size():
				spent_item_stacks.append(false)

			for item_index in indexes:
				var target_item = player_hotbar.return_slot_data_by_index(item_index)
				if target_item.quantity < total_qty:
					num_of_items_removed = target_item.quantity
				elif target_item.quantity >= total_qty:
					num_of_items_removed = total_qty
				player_hotbar.remove_item(item_index, total_qty * quantity_multiplier)
				spent_item_stacks[n] = true
				if target_item.item_data.stackable == true:
					# This check prevents issues consuming non stackable items
					total_qty -= num_of_items_removed
				
				if !spent_item_stacks.has(false) and total_qty > 0:
					find_and_remove_items_from_inventory(item, total_qty, num_of_items_removed)
				n += 1

		else:
			find_and_remove_items_from_inventory(item, total_qty, num_of_items_removed)

func find_and_remove_items_from_inventory(item, total_qty, num_of_items_removed):
	# find and remove from inventory
	var inventory_item = player_inventory.is_item_in_inventory_return_bool(item)
	if inventory_item:
		var indexes = return_array_values_at_odd_indexes(inventory_item_data_array[item])
		var qty = listed_crafting_requirements[item][0]
		if total_qty == 0:
			total_qty = qty
		var qty_array = return_array_values_at_even_indexes(inventory_item_data_array[item])
		var n = 0
		for item_index in indexes:
			var target_item = player_inventory.return_slot_data_by_index(item_index)
			if num_of_items_removed <= 0:
				if target_item.quantity < total_qty:
					num_of_items_removed = target_item.quantity
				elif target_item.quantity >= total_qty:
					num_of_items_removed = total_qty
			player_inventory.remove_item(item_index, total_qty * quantity_multiplier)
			if target_item.item_data.stackable == true:
				total_qty -= num_of_items_removed
			if total_qty < 0:
				total_qty = 0
			n += 1

func give_player_crafted_item():
	# need to check if slots are available, then if a stack exists and if 
	# it can be combined, if theres no slots but a stack exists and can't be combined
	# place in inventory, if that's not possible then reject ability to collect items
	
	# check if slots are available
	# check if it can be stacked
	# must prioritise hotbar
	#craft.disabled = false
	var is_there_an_empty_slot_hotbar = player_hotbar.are_there_slots_available()
	var is_there_an_empty_slot_inventory = player_inventory.are_there_slots_available()

	var is_in_hot_bar : SlotData = player_hotbar.is_item_in_inventory_return_slot_data(output_item.item_data.name)
	#var is_in_inventory : SlotData = player_inventory.is_item_in_inventory_return_slot_data(output_item.item_data.name)
	#player_hotbar.add_to_inventory_with_quantity(output_item, output_item.quantity)
	#player_inventory.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if is_in_hot_bar and is_in_hot_bar.quantity < 64 and is_there_an_empty_slot_hotbar:
		player_hotbar.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if is_in_hot_bar and !is_there_an_empty_slot_hotbar:
		if return_if_total_less_than_max_stack_size(is_in_hot_bar):
			player_hotbar.add_to_inventory_with_quantity(output_item, output_item.quantity)
		else:
			player_inventory.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if !is_in_hot_bar and is_there_an_empty_slot_hotbar:
		player_hotbar.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if !is_in_hot_bar and !is_there_an_empty_slot_hotbar:
		player_inventory.add_to_inventory_with_quantity(output_item, output_item.quantity)

func return_if_total_less_than_max_stack_size(slot_data : SlotData) -> bool:
	var total = slot_data.quantity + output_item.quantity
	if total <= 64:
		return true
	else:
		return false

func _on_minus_pressed() -> void:
	if button_that_was_fired:
		var value = int(quantity_label.text)
		value -= 1
		if value < 1:
			value = 1
		
		quantity_label.text = str(value)
		quantity_multiplier = value
		button_that_was_fired.resend_crafting_data()


func _on_plus_pressed() -> void:
	if button_that_was_fired:
		var value = int(quantity_label.text)
		value += 1
		if value > 10:
			value = 10
		
		quantity_label.text = str(value)
		quantity_multiplier = value
		button_that_was_fired.resend_crafting_data()


func _on_close_pressed() -> void:
	toggle_self_ui()


func _on_tab_button_mouse_entered(source: Control) -> void:
	if tab_button_that_was_pressed and source.name != tab_button_that_was_pressed.name:
		source.modulate = hover_and_selected_button_colour
	elif !tab_button_that_was_pressed:
		source.modulate = hover_and_selected_button_colour


func _on_tab_button_mouse_exited(source: Control) -> void:
	if tab_button_that_was_pressed and source.name != tab_button_that_was_pressed.name:
		source.modulate = normal_button_colour
	elif !tab_button_that_was_pressed:
		source.modulate = normal_button_colour


func _on_tab_button_gui_input(event: InputEvent, source: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			for tab in tab_buttons:
				if tab.name == source.name:
					tab.modulate = hover_and_selected_button_colour
					tab_button_that_was_pressed = tab
				else:
					tab.modulate = normal_button_colour

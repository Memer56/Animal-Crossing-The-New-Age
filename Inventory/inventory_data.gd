extends Resource
class_name InventoryData

signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index : int, button : int)

@export var slot_datas : Array[SlotData]
@export var duplicate_slot_data : bool = false

func grab_slot_data(grabbed_slot_data : SlotData, index : int) -> SlotData:
	var slot_data = slot_datas[index]
	grabbed_slot_data = slot_data
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		#Sends signal to player hitbox to confirm item was removed from inventory type InventoryDataEquip
		EventBus.armour_piece_unequipped.emit(self, grabbed_slot_data, index)
		return slot_data
	else:
		return null


func drop_slot_data(grabbed_slot_data: SlotData, index : int) -> SlotData:
	var slot_data = slot_datas[index]
	
	var return_slot_data: SlotData
	if slot_data and slot_data.can_drop_and_fully_merge_by_id(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data
	
	
	inventory_updated.emit(self)
	return return_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index : int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
		print(grabbed_slot_data.item_data.name)
		EventBus.armour_piece_equipped.emit(grabbed_slot_data, index)
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with_without_slot_data_overflow(grabbed_slot_data.create_single_slot_data())
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null

func use_slot_data(index: int) -> void:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		return
	
	if slot_data.item_data is ItemDataConsumable:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			slot_datas[index] = null
	
	if slot_data.item_data is ItemDataPlant:
		if EventBus.can_place:
			slot_data.quantity -= 1
			if slot_data.quantity < 1:
				slot_datas[index] = null
	
	if slot_data.item_data is ItemDataCurrency:
		EventBus.coins += slot_data.quantity
		slot_datas[index] = null
	
	EventBus.player.use_slot_data(slot_data)
	
	inventory_updated.emit(self)



func pick_up_slot_data(slot_data : SlotData) -> bool:
	var copy_slot_data = get_slot_data_copy(slot_data)
	
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_fully_merge_by_id(copy_slot_data):
			slot_datas[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			return true
	
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = copy_slot_data
			inventory_updated.emit(self)
			return true
	
	return false

func add_to_inventory(slot_data : SlotData) -> bool:
	var copy_slot_data = get_slot_data_copy(slot_data)
	
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_fully_merge_by_id(copy_slot_data):
			slot_datas[index].merge_by_one(copy_slot_data)
			inventory_updated.emit(self)
			return true
	# The loop below triggers first if the slot is empty
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = copy_slot_data
			inventory_updated.emit(self)
			return true
	
	return false

func add_to_inventory_with_quantity(slot_data : SlotData, quantity : int):
	var copy_slot_data = get_slot_data_copy(slot_data)
	copy_slot_data.quantity = quantity
	
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_fully_merge_by_id(copy_slot_data):
			slot_datas[index].fully_merge_with(copy_slot_data)
			inventory_updated.emit(self)
			return true
	# The loop below triggers first if the slot is empty
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = copy_slot_data
			inventory_updated.emit(self)
			return true
	
	return false

func add_to_inventory_at_index(slot_data : SlotData, quantity : int, index : int):
	var copy_slot_data = get_slot_data_copy(slot_data)
	copy_slot_data.quantity = quantity
	
	if slot_datas[index] and slot_datas[index].can_fully_merge_by_id(copy_slot_data):
		slot_datas[index].fully_merge_with(copy_slot_data)
		inventory_updated.emit(self)
		return true
# The check below triggers first if the slot is empty
	if not slot_datas[index]:
		slot_datas[index] = copy_slot_data
		inventory_updated.emit(self)
		return true
	
	return false

func get_slot_data_copy(slot_data : SlotData) -> SlotData:
	var new_slot_data = SlotData.new()
	if slot_data.item_data is ItemDataConsumable:
		new_slot_data.item_data = ItemDataConsumable.new()
	elif slot_data.item_data is ItemDataCurrency:
		new_slot_data.item_data = ItemDataCurrency.new()
	else:
		new_slot_data.item_data = ItemData.new()
	duplicate_slot_data = false
	new_slot_data.item_data.name = slot_data.item_data.name
	new_slot_data.item_data.description = slot_data.item_data.description
	new_slot_data.item_data.stackable = slot_data.item_data.stackable
	new_slot_data.item_data.price = slot_data.item_data.price
	new_slot_data.item_data.sell_value = slot_data.item_data.sell_value
	new_slot_data.item_data.texture = slot_data.item_data.texture
	new_slot_data.item_data.mesh = slot_data.item_data.mesh
	new_slot_data.item_data.mining_value = slot_data.item_data.mining_value
	new_slot_data.item_data.ID = slot_data.item_data.ID
	new_slot_data.quantity = slot_data.quantity
	return new_slot_data


func sell_item(slot_data : SlotData, index : int):
	slot_data = slot_datas[index]
	
	if not slot_data:
		return
	
	if slot_data.item_data is ItemDataConsumable or ItemData:
		var coins_due = slot_data.item_data.sell_value * slot_data.quantity
		slot_data.quantity -= slot_data.quantity
		EventBus.coins += coins_due
		if slot_data.quantity < 1:
			slot_datas[index] = null
	
	inventory_updated.emit(self)

func is_item_in_inventory(material : SlotData) -> int:
	for index in slot_datas.size():
		if slot_datas[index]:
			if slot_datas[index].item_data.name == material.item_data.name:
				return index
	return -1

#This function below exists because I'm too lazy to rewrite the above one and change the code that uses it
func locate_item_in_inventory_by_name(item_name : String) -> Array:
	var data : Array
	for index in slot_datas.size():
		if slot_datas[index]:
			if slot_datas[index].item_data.name == item_name:
				data.append(slot_datas[index].quantity)
				data.append(index)
	return data

func locate_item_in_inventory_by_name_return_dictionary(item_name : String) -> Dictionary:
	# will only return the quantity of the item
	var item_data : Dictionary
	for index in slot_datas.size():
		if slot_datas[index]:
			if slot_datas[index].item_data.name == item_name:
				item_data[slot_datas[index].item_data.name] = slot_datas[index].quantity
	return item_data

func is_item_in_inventory_return_bool(item_name : String) -> bool:
	for index in slot_datas.size():
		if slot_datas[index]:
			if slot_datas[index].item_data.name == item_name:
				return true
	return false

func is_item_in_inventory_return_slot_data(item_name : String) -> SlotData:
	var slot_data : SlotData
	print("item name: ", item_name)
	for index in slot_datas.size():
		if slot_datas[index]:
			print("Found slot data: ", slot_datas[index].item_data.name)
			if slot_datas[index].item_data.name == item_name:
				print("Item match found")
				slot_data = slot_datas[index]
				return slot_data
	return null

func remove_item(index : int, amount : int):
	if slot_datas[index]:
		slot_datas[index].quantity -= amount
		if slot_datas[index].quantity < 1:
			slot_datas[index] = null
		
		inventory_updated.emit(self)

func remove_item_if_quantity_is_higher(index : int, amount : int):
	if slot_datas[index]:
		if slot_datas[index].quantity >= amount:
			slot_datas[index].quantity -= amount
			if slot_datas[index].quantity < 1:
				slot_datas[index] = null
			
			inventory_updated.emit(self)

func return_slot_data_by_index(index : int) -> SlotData:
	if slot_datas[index]:
		return slot_datas[index]
	return null

func are_there_slots_available() -> bool:
	var number_of_empty_slots : int = 0
	for index in slot_datas.size():
		if !slot_datas[index]:
			number_of_empty_slots += 1
		if number_of_empty_slots >= 1:
			return true
	return false

func return_empty_slots() -> Array:
	var empty_slots : Array
	for index in slot_datas.size():
		if !slot_datas[index]:
			empty_slots.append(index)
	return empty_slots

func on_slot_clicked(index : int, button : int) -> void:
	inventory_interact.emit(self, index, button)

func index_value(index : int):
	print(index)

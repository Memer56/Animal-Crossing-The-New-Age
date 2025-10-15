extends InventoryData
class_name InventoryDataEquip


# Function called with left mouse click
func drop_slot_data(grabbed_slot_data: SlotData, index : int) -> SlotData:
	
	if not grabbed_slot_data.item_data is ItemDataEquip:
		return grabbed_slot_data
	
	
	return super.drop_single_slot_data(grabbed_slot_data, index)


# Function called with right mouse click
func drop_single_slot_data(grabbed_slot_data: SlotData, index : int) -> SlotData:
	
	if not grabbed_slot_data.item_data is ItemDataEquip:
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)

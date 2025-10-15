extends Resource
class_name SlotData
const MAX_STACK_SIZE = 64

@export var item_data : ItemData
#@export_range(1, MAX_STACK_SIZE) var quantity : int = 1 : set = set_quantity
@export var quantity : int = 1

func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data.ID == other_slot_data.item_data.ID and item_data.stackable and quantity < MAX_STACK_SIZE

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	var total_quantity = quantity + other_slot_data.quantity
	return item_data == other_slot_data.item_data and item_data.stackable and total_quantity <= MAX_STACK_SIZE

func can_drop_and_fully_merge_by_id(other_slot_data : SlotData) -> bool:
	var total_quantity = quantity + other_slot_data.quantity
	return item_data.ID == other_slot_data.item_data.ID and item_data.stackable and total_quantity <= MAX_STACK_SIZE

func can_fully_merge_by_id(other_slot_data : SlotData) -> bool:
	#USE THIS FOR ADDING ITEMS TO INVENTORY VIA CODE
	#Merging can happen if stack size is not at max
	#var total_quantity = quantity + other_slot_data.quantity
	return item_data.ID == other_slot_data.item_data.ID and item_data.stackable and quantity < MAX_STACK_SIZE
	
func fully_merge_with(other_slot_data: SlotData) -> void:
	quantity += other_slot_data.quantity
	if quantity >= MAX_STACK_SIZE:
		var qty_overflow = quantity - MAX_STACK_SIZE
		if qty_overflow > 0:
			other_slot_data.quantity = qty_overflow
		quantity = MAX_STACK_SIZE
		EventBus.create_overflow_slot_data.emit(other_slot_data)
		create_overflow_single_slot_data(other_slot_data)

func fully_merge_with_without_slot_data_overflow(other_slot_data: SlotData):
	quantity += other_slot_data.quantity
	if quantity >= MAX_STACK_SIZE:
		create_overflow_single_slot_data(other_slot_data)


func merge_by_one(other_slot_data: SlotData) -> void:
	quantity += 1
	if quantity >= MAX_STACK_SIZE:
		EventBus.duplicate_slot_data_info.emit()
		create_overflow_single_slot_data(other_slot_data)

func create_single_slot_data() -> SlotData:
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data

func create_overflow_single_slot_data(slot_data : SlotData):
	# this does nothing
	var new_slot_data = slot_data.duplicate()
	return new_slot_data
	#EventBus.send_slot_info_to_new_slot.emit(new_slot_data)

func set_quantity(value: int) -> void:
	quantity = value
	if quantity > MAX_STACK_SIZE:
		quantity = MAX_STACK_SIZE
	if quantity > 1 and not item_data.stackable:
		quantity = 1
		push_error("%s is not stackable, setting quantity to 1" % item_data.name)

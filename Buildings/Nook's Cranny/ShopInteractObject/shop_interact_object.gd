extends StaticBody3D

@export var has_been_sold : bool = false
@export var item_value : int
@export var item_slot_data : SlotData
@export var has_display_item : bool = false
@onready var sold_out_sign_model: Node3D = $"sold out sign model"

func display_object_information():
	if has_been_sold:
		EventBus.display_speech_bubble.emit(["Sorry, this item is sold out"], "timmy", [false, null])
	else:
		var value = format_with_commas(item_value)
		EventBus.display_speech_bubble.emit(["This [color=green]" + item_slot_data.item_data.name + "[/color] worth [color=blue]" + value + " Bells[/color]. Would you like to buy it?", "Thanks for buying.", "Well, let us know if you need anything else!"], "Timmy", [true, 0, self])

func set_information(_item_value : int, _item_slot_data : SlotData, _has_been_sold):
	item_value = _item_value
	item_slot_data = _item_slot_data
	has_been_sold = _has_been_sold
	if has_been_sold:
		set_display_to_sold()

func set_display_to_sold():
	has_been_sold = true
	for child in get_children():
		if child.is_in_group("DisplayItem"):
			child.hide()
			sold_out_sign_model.show()

func format_with_commas(number: int) -> String:
	var number_as_string : String = str(number)
	var output_string : String = ""
	var last_index : int = number_as_string.length() - 1
	#For each digit in the number...
	for index in range(number_as_string.length()):
		#add that digit to the output string, and then...
		output_string = output_string + number_as_string.substr(index,1)
		#if the index is at the thousandths, millions, billionths place, etc.
		#i.e. where you would put a comma, then insert a comma after that digit.
		if (last_index - index) % 3 == 0 and index != last_index:
			output_string = output_string + ","
	return output_string

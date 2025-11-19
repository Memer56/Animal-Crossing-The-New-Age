extends Node

const PLAYER_TENT = preload("uid://du1vi2sn7tjhm")

var object_spawn_position : Vector3
var current_object_name_to_spawn : String
var item_to_remove_inventory_data : InventoryData
var item_to_remove_slot_index : int
var all_ground_ray_casts_collide : bool = true
var colliding_with_another_object : bool = false

func trigger_confirm_message_for_building():
	EventBus.trigger_confirm_message.emit("Would you like to place this here?")

func spawn_object():
	var object
	match current_object_name_to_spawn:
		"Tent":
			object = PLAYER_TENT.instantiate()
	
	if verify_valid_placement():
		print("Successfully placed object")
		get_tree().root.get_node("Main/MainIslandNavMesh").add_child(object)
		object.global_position = object_spawn_position
		remotely_remove_item(item_to_remove_inventory_data, item_to_remove_slot_index)
		if EventBus.is_in_overworld:
			EventBus.bake_nav_mesh.emit()
	else:
		EventBus.display_speech_bubble.emit("Sorry this can't be placed [color=red]here[/color]", "Sorry!")

func verify_valid_placement() -> bool:
	if all_ground_ray_casts_collide and !colliding_with_another_object:
		return true
	return false

func remotely_remove_item(inventory_data : InventoryData, slot_index : int):
	inventory_data.remove_item(slot_index, 1)

extends Node

const DRESS_1 = preload("uid://duepwdb7eo68a")
const DRESS_2 = preload("uid://npvkb08frqdy")

## Buildings constsssssssss
const PLAYER_TENT = preload("uid://du1vi2sn7tjhm")


signal create_overflow_slot_data(slot_data : SlotData)
signal duplicate_slot_data_info
signal armour_piece_equipped(grabbed_slot_data : SlotData, index : int)
signal armour_piece_unequipped(inventory_data : InventoryDataEquip, grabbed_slot_data : SlotData, index : int)
signal update_clothes_anim(anim_name : String, anim_speed : float)
signal trigger_confirm_message(main_text : String)
signal bake_nav_mesh
signal display_speech_bubble(speech_text_array : Array[String], npc_name : String)
signal save_game_data
signal load_game_data

var player
var can_place : bool = true
var held_item_slot_data : SlotData
var coins : int
var game_paused : bool = false
var room_to_spawn : String
var is_in_overworld : bool = true
var trigger_building_exit_event : bool = false
var player_can_leave_nav_mesh : bool = true # Defaulted to true to allow correct spanwing placement
var game_in_start_up : bool = true
var last_building_entered : Dictionary = {
	"building pos": Vector3.ZERO,
	"building node": null
}


func return_clothing_scene(clothing_name : String) -> PackedScene:
	var clothing : PackedScene
	match clothing_name:
		"DRESS_1":
			clothing = DRESS_1
		"DRESS_2":
			clothing = DRESS_2
	
	return clothing

func return_building_to_spawn(building_name : String) -> Node:
	var building : Node
	match building_name:
		"PlayerTent":
			building = PLAYER_TENT.instantiate()
	
	return building

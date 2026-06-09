extends Node

const DRESS_1 = preload("uid://duepwdb7eo68a")
const DRESS_2 = preload("uid://npvkb08frqdy")

### Button sounds ###
const MENU_HOVER_SOUND_EFFECT = preload("uid://7krrlm2un7o6")
const MENU_SELECTION_SOUND_EFFECT = preload("uid://cbk6420stpgs6")

signal create_overflow_slot_data(slot_data : SlotData)
signal duplicate_slot_data_info
signal armour_piece_equipped(grabbed_slot_data : SlotData, index : int)
signal armour_piece_unequipped(inventory_data : InventoryDataEquip, grabbed_slot_data : SlotData, index : int)
signal update_clothes_anim(anim_name : String, anim_speed : float)
signal trigger_confirm_message(main_text : String)
signal bake_nav_mesh
## Arg 1 = Speech to send, Arg 2 = NPC Name, Arg 3 = Array[at what indexes do questions occur], Arg 4 = The item that is to be given if there is one
signal display_speech_bubble(speech_text_array : Array[String], npc_name : String, questions_at_index : Array, item_to_be_given : SlotData)
signal save_game_data
signal load_game_data
signal send_nav_region(nav_region : NavigationRegion3D)
signal toggle_atm_ui
signal toggle_crafting_ui
signal toggle_service_buildings_lights(true_or_false : bool)
signal toggle_fade(true_or_false : bool)
signal remove_tom_and_free_player

var player
## Index 0 = Player Name / Index 1 = Skin Colour / Index 2 = Hair Colour / Index 3 = Player Position
var player_customisations : Array
var player_balance : int = 0
var savings_balance : int = 999999999
var loan_balance : int = 100
var previous_loan_balance : int = 0
var player_is_debt_free : bool = false
var can_place : bool = true
var held_item_slot_data : SlotData
var game_paused : bool = false
var room_to_spawn : String
var is_in_overworld : bool = false
var is_in_player_house : bool = false
var trigger_building_exit_event : bool = false
var game_in_start_up : bool = true
var game_is_new_save : bool = true
var current_save_file_id : String
var is_returning_to_main_menu : bool = false
var last_building_entered : Dictionary = {
	"building pos": Vector3.ZERO,
	"building node": null
}
var found_save_file_ids : Array
var controller_found : bool = false
var nooks_cranny_has_set_items : bool = false
var nooks_cranny_displays : Dictionary[String, Array]
var current_shop_interact_object : StaticBody3D
var item_was_bought_during_visit : bool = false
var tree_nav_mesh : NavigationRegion3D
var current_trees : Array[Array]
var house_level : int = 0
var world_time : float = 0.3
var npc_houses : Dictionary
##For checking if shops and such have been set to close
var service_buildings_closed : bool = false
var service_buildings_lights_on : bool = false
## index 0 = Island Name / index 1 = Island Scene String
var selected_island_info : Array
var sound_settings : Array[float] = [100.0, 100.0, 100.0]
var next_scene : String
var playback
var game_state
var quest_level : int = 1

enum {
	PLAY,
	INTRO
}

func _ready() -> void:
	game_state = PLAY

func _enter_tree() -> void:
	var audio_player : AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player.bus = &"SFX"
	
	var stream : AudioStreamPolyphonic = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	audio_player.stream = stream
	audio_player.play()
	playback = audio_player.get_stream_playback()
	
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node : Node):
	if node is Button:
		if !node.mouse_entered.is_connected(_play_hover):
			node.mouse_entered.connect(_play_hover)

		if !node.pressed.is_connected(_play_pressed):
			node.pressed.connect(_play_pressed)
	
	if node is Panel:
		if node.has_meta("Sound"):
			if !node.mouse_entered.is_connected(_play_hover):
				node.mouse_entered.connect(_play_hover)

			if !node.gui_input.is_connected(_play_gui_input):
				node.gui_input.connect(_play_gui_input)

func _play_hover():
	playback.play_stream(MENU_HOVER_SOUND_EFFECT)

func _play_pressed():
	playback.play_stream(MENU_SELECTION_SOUND_EFFECT)

func _play_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MASK_LEFT and event.is_released():
			playback.play_stream(MENU_SELECTION_SOUND_EFFECT)

func increase_quest_level():
	##Increases the quest level, this tracks how far along the player is in their quests
	quest_level += 1

func return_clothing_scene(clothing_name : String) -> PackedScene:
	var clothing : PackedScene
	match clothing_name:
		"DRESS_1":
			clothing = DRESS_1
		"DRESS_2":
			clothing = DRESS_2
	
	return clothing

func deduct_funds_from_account(amount : int):
	savings_balance -= amount

func add_funds_to_account(amount : int):
	savings_balance += amount

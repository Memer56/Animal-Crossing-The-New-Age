extends Node3D # THIS IS THE ROOM SCRIPT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

const PICK_UP = preload("uid://c8p87t4ex6hyc")

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/InventoryInterface/HotBarInventory
@export var rooms : Dictionary[String, PackedScene]
@onready var player_spawn_point: Marker3D = $PlayerSpawnPoint
@onready var build_camera: Camera3D = $BuildCamera
@onready var transition_camera: Camera3D = $TransitionCamera

var lights : Array
var save : SaveGame
var save_json_ids : SaveGame
var characters  = "abcdefghijklmnopqrstuvwxyz"

func _ready() -> void:
	EventBus.player.toggle_inventory.connect(toggle_inventory_interface)
	EventBus.save_game_data.connect(save_game_data)
	hot_bar_inventory.send_held_slot_data.connect(EventBus.player.set_item_in_hand)
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)
	connect_toggle_external_inventory_signal()
	spawn_room()
	EventBus.player.global_position = player_spawn_point.global_position
	EventBus.player.player_node.global_rotation_degrees = Vector3(0, 180, 0)
	FadeCanvasLayer.trigger_scene_change_fade(false)
	EventBus.is_in_overworld = false
	EventBus.player_can_leave_nav_mesh = true
	BuildManager.build_camera = build_camera
	BuildManager.transition_camera = transition_camera
	BuildManager.speed = 1.0 # For build camera movement speed
	load_game_data()

func spawn_room():
	var room_to_spawn
	
	match EventBus.room_to_spawn:
		"Town Hall":
			room_to_spawn = rooms["Town Hall"].instantiate()
		"Nook's Cranny":
			room_to_spawn = rooms["Nook's Cranny"].instantiate()
		"Tent Room":
			room_to_spawn = rooms["Tent Room"].instantiate()
			EventBus.is_in_player_house = true
		"House Room":
			room_to_spawn = rooms["House Room"].instantiate()
			EventBus.is_in_player_house = true
	
	if room_to_spawn:
		add_child(room_to_spawn)
	else:
		push_error("No Valid Room Was Found ---- room.gd")

func connect_toggle_external_inventory_signal():
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.player_inventory.visible = not inventory_interface.player_inventory.visible
	
	if inventory_interface.player_inventory.visible:
		EventBus.game_paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#get_tree().paused = true
		inventory_interface.player_inventory.visible = true
		#inventory_interface.equip_inventory.visible = true
	else:
#		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		EventBus.game_paused = false
		inventory_interface.player_inventory.visible = false
		#inventory_interface.equip_inventory.visible = false
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()



func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PICK_UP.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = EventBus.player.get_drop_point()
	add_child(pick_up)

func grab_light_sources():
	pass

func save_game_data():
	# thus is slightly altered from the Main script to prevent incorrect saving and loading
	var save = SaveGame.new()
	var value : int = 2
	save.inventory = EventBus.player.inventory_data
	save.hotbar_inventory = EventBus.player.hotbar_inventory_data
	
	if EventBus.game_is_new_save:
		EventBus.game_is_new_save = false
		EventBus.current_save_file_id = generate_save_file_id()
	
	if EventBus.is_in_player_house:
		for node in get_tree().get_nodes_in_group("SaveObject"):
			if save.interior_object_info.has(node.self_slot_data.item_data.name):
				save.interior_object_info[node.self_slot_data.item_data.name + " " + str(value)] = node.global_transform
				value += 1
			else:
				save.interior_object_info[node.self_slot_data.item_data.name] = node.global_transform

		BuildManager.interior_objects = save.interior_object_info
	else:
		save.interior_object_info = BuildManager.interior_objects
	
	save.exterior_object_info = BuildManager.exterior_objects
	save.player_balance = EventBus.player_balance
	save.savings_balance = EventBus.savings_balance
	save.loan_balance = EventBus.loan_balance
	save.previous_loan_balance = EventBus.previous_loan_balance
	save.player_is_debt_free = EventBus.player_is_debt_free
	save.trees = EventBus.current_trees
	save.house_level = EventBus.house_level
	save.world_time = EventBus.world_time
	
	save.write_savegame_data(EventBus.current_save_file_id)

func load_game_data():
	if SaveGame.save_exists(EventBus.current_save_file_id) == false:
		EventBus.display_speech_bubble.emit(["Error loading save file!"], "Error", [false, null])
		return
	
	save = SaveGame.load_savegame_data(EventBus.current_save_file_id)
	EventBus.player.inventory_data.slot_datas = save.inventory.slot_datas
	EventBus.player.hotbar_inventory_data.slot_datas = save.hotbar_inventory.slot_datas
	EventBus.player_balance = save.player_balance
	EventBus.savings_balance = save.savings_balance
	EventBus.loan_balance = save.loan_balance
	EventBus.previous_loan_balance = save.previous_loan_balance
	EventBus.player_is_debt_free = save.player_is_debt_free
	EventBus.house_level = save.house_level
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)
	load_object_data()

func load_object_data():
	if EventBus.current_save_file_id and EventBus.is_in_player_house:
		save = SaveGame.load_savegame_data(EventBus.current_save_file_id)
		var object
		if save.interior_object_info:
			for new_object in save.interior_object_info:
				BuildManager.current_object_name_to_spawn = new_object
				object = BuildManager.get_object_to_spawn()
				add_child(object)
				object.global_transform = save.interior_object_info[new_object]
				EventBus.save_game_data.emit()

func generate_save_file_id() -> String:
	var id : String
	var random_letter_int : int = len(characters)
	for i in range(4):
		id += characters[randi()%random_letter_int]
	return " " + id + " " # empty quotes add empty spacing around id tag

extends Node3D # THIS IS THE ROOM SCRIPT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

const PICK_UP = preload("uid://c8p87t4ex6hyc")

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/InventoryInterface/HotBarInventory
@export var rooms : Dictionary[String, PackedScene]
@onready var player_spawn_point: Marker3D = $PlayerSpawnPoint

var lights : Array

func _ready() -> void:
	EventBus.player.toggle_inventory.connect(toggle_inventory_interface)
	hot_bar_inventory.send_held_slot_data.connect(EventBus.player.set_item_in_hand)
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)
	connect_toggle_external_inventory_signal()
	spawn_room()
	EventBus.player.global_position = player_spawn_point.global_position
	EventBus.player.player_node.global_rotation_degrees = Vector3(0, 180, 0)
	FadeCanvasLayer.trigger_scene_change_fade(false)
	EventBus.is_in_overworld = false
	#begin_river_generation()

func spawn_room():
	var room_to_spawn
	
	match EventBus.room_to_spawn:
		"Town Hall":
			room_to_spawn = rooms["Town Hall"].instantiate()
		"Tent Room":
			room_to_spawn = rooms["Tent Room"].instantiate()
		"House Room":
			room_to_spawn = rooms["House Room"].instantiate()
	
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

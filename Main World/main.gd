extends Node3D
# Set Roughness value to 0.5 and Normal to 0.1
######## ADD PIANO THAT PLAYS SONGS YOU RECORDED #####################
const PICK_UP = preload("uid://c8p87t4ex6hyc")

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/InventoryInterface/HotBarInventory
@onready var main_island_nav_mesh: NavigationRegion3D = $MainIslandNavMesh

var save : SaveGame
var save_buildings : SaveGame

func _ready() -> void:
	EventBus.player.toggle_inventory.connect(toggle_inventory_interface)
	EventBus.bake_nav_mesh.connect(bake_nav_mesh)
	EventBus.save_game_data.connect(save_game_data)
	EventBus.load_game_data.connect(load_game_data)
	hot_bar_inventory.send_held_slot_data.connect(EventBus.player.set_item_in_hand)
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)
	connect_toggle_external_inventory_signal()
	trigger_fade()
	load_overworld_buildings()
	#load_game_data()

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

func load_overworld_buildings():
	# This will be needed for player placed villager buildings and house
	pass


func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PICK_UP.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = EventBus.player.get_drop_point()
	add_child(pick_up)

func trigger_fade():
	if !EventBus.is_in_overworld:
		FadeCanvasLayer.trigger_scene_change_fade(false)
		EventBus.is_in_overworld = true

func bake_nav_mesh():
	main_island_nav_mesh.bake_navigation_mesh()

func save_game_data():
	var save = SaveGame.new()
	var save_builings = SaveGame.new()
	if EventBus.is_in_overworld:
		for node in get_tree().get_nodes_in_group("SaveBuilding"):
			save_builings.building_info[node.name] = node.global_position
	save.inventory = EventBus.player.inventory_data
	save.hotbar_inventory = EventBus.player.hotbar_inventory_data
	save.write_savegame_data()
	save_builings.write_savegame_data_buildings()

func load_game_data():
	if SaveGame.save_exists() == false:
		EventBus.display_speech_bubble.emit(["Error loading save file!"], "Error")
		return
	if SaveGame.save_exists_buildings() == false:
		return
	
	save = SaveGame.load_savegame_data()
	EventBus.player.inventory_data.slot_datas = save.inventory.slot_datas
	EventBus.player.hotbar_inventory_data.slot_datas = save.hotbar_inventory.slot_datas
	save_buildings = SaveGame.load_savegame_data_buildings()
	for node in save_buildings.building_info:
		var building = EventBus.return_building_to_spawn(node)
		main_island_nav_mesh.add_child(building)
		building.global_position = save_buildings.building_info[node]
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)

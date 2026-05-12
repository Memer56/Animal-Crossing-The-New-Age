extends Node3D
# Set Roughness value to 0.5 and Normal to 0.1
######## ADD PIANO THAT PLAYS SONGS YOU RECORDED #####################
const PICK_UP = preload("uid://c8p87t4ex6hyc")
const TOM_NOOK = preload("uid://dhvnwgofhxw1i")
const GENERIC_TREE = preload("uid://dc2iy76lfy0ow")

###### Navigaton and boundry bullshit
const PLAYER_NAV_BOUNDRY = preload("uid://cixmss1j0ygbm")

### Spawmed if save didn't load ###
const SAVE_DIDNT_LOAD = preload("uid://dlk1501txn687")
const BLACK_SKY = preload("uid://dxvl6jpkjyy33")

#### Item data resources #####
const STONE_ITEM = preload("uid://801bd84rk176")

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/InventoryInterface/HotBarInventory
@onready var main_island_nav_mesh: NavigationRegion3D = $MainIslandNavMesh
@onready var town_hall: StaticBody3D = $MainIslandNavMesh/TownHall
@onready var world_environment: WorldEnvironment = $Sky/WorldEnvironment
@onready var sun: DirectionalLight3D = $Sky/Sun
@export var navigation_mesh : NavigationRegion3D
@onready var build_camera: Camera3D = $BuildCamera
@onready var transition_camera: Camera3D = $TransitionCamera
@export var gizmo : Gizmo3D

var save : SaveGame
var characters  = "abcdefghijklmnopqrstuvwxyz"
var map_rid : RID
var max_attempts : int = 10
var min_distance : float = 50.0
var objects_to_avoid : Array

func _ready() -> void:
	trigger_fade()
	EventBus.player.toggle_inventory.connect(toggle_inventory_interface)
	EventBus.bake_nav_mesh.connect(bake_nav_mesh)
	EventBus.save_game_data.connect(save_game_data)
	EventBus.load_game_data.connect(load_game_data)
	EventBus.load_player_island_nav_mesh_bounds.connect(load_player_nav_refrence_island)
	hot_bar_inventory.send_held_slot_data.connect(EventBus.player.set_item_in_hand)
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)
	load_player_nav_refrence_island("Island 1")
	connect_toggle_external_inventory_signal()
	send_nav_region_to_npcs()
	BuildManager.build_camera = build_camera
	BuildManager.transition_camera = transition_camera
	BuildManager.speed = 10.0 # For build camera movement speed
	EventBus.is_in_overworld = true
	EventBus.is_in_player_house = false
	EventBus.current_trees.clear()
	if EventBus.game_is_new_save:
		EventBus.nooks_cranny_has_set_items = false # in the event player doesn't close game before starting new save
		EventBus.loan_balance = 140000
		EventBus.previous_loan_balance = EventBus.loan_balance
		spawn_trees()
	else:
		load_game_data()
		if BuildManager.home_can_upgrade:
			BuildManager.upgrade_home()
	spawn_stones()
	bake_nav_mesh()

func init_new_savegame_events():
	var tom = TOM_NOOK.instantiate()
	add_child(tom)
	tom.global_position = town_hall.global_position

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
		EventBus.player.state = EventBus.player.FREEZE_PLAYER
	else:
#		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		EventBus.game_paused = false
		inventory_interface.player_inventory.visible = false
		#inventory_interface.equip_inventory.visible = false
		EventBus.player.state = EventBus.player.IDLE
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()


func _on_inventory_interface_drop_slot_data(slot_data):
	if slot_data:
		var pick_up = PICK_UP.instantiate()
		pick_up.slot_data = slot_data
		pick_up.position = EventBus.player.get_drop_point()
		add_child(pick_up)
		pick_up.label_3d.text = slot_data.item_data.name

func trigger_fade():
	FadeCanvasLayer.trigger_scene_change_fade(false)

func bake_nav_mesh():
	main_island_nav_mesh.bake_navigation_mesh(true)

func save_game_data():
	var save = SaveGame.new()
	var value : int = 2

	for node in get_tree().get_nodes_in_group("SaveObject"):
		if save.exterior_object_info.has(node.self_slot_data.item_data.name):
			save.exterior_object_info[node.self_slot_data.item_data.name + " " + str(value)] = node.global_transform
			value += 1
		else:
			save.exterior_object_info[node.self_slot_data.item_data.name] = node.global_transform
	
	BuildManager.exterior_objects = save.exterior_object_info
	save.interior_object_info = BuildManager.interior_objects
	
	save.inventory = EventBus.player.inventory_data
	save.hotbar_inventory = EventBus.player.hotbar_inventory_data
	save.player_balance = EventBus.player_balance
	save.savings_balance = EventBus.savings_balance
	save.loan_balance = EventBus.loan_balance
	save.previous_loan_balance = EventBus.previous_loan_balance
	save.player_is_debt_free = EventBus.player_is_debt_free
	save.house_level = EventBus.house_level
	save.trees = EventBus.current_trees
	save.world_time = EventBus.world_time
	
	if EventBus.game_is_new_save:
		EventBus.game_is_new_save = false
		EventBus.current_save_file_id = generate_save_file_id()
	
	save.write_savegame_data(EventBus.current_save_file_id)

func load_game_data():
	if SaveGame.save_exists(EventBus.current_save_file_id) == true:
		load_player_data()
		load_object_data()

func load_player_data():
	if EventBus.current_save_file_id:
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

func load_object_data():
	if EventBus.current_save_file_id:
		save = SaveGame.load_savegame_data(EventBus.current_save_file_id)
		var object
		for new_object in save.exterior_object_info:
			BuildManager.current_object_name_to_spawn = new_object
			object = BuildManager.get_object_to_spawn()
			if EventBus.is_in_overworld:
				main_island_nav_mesh.add_child(object)
			else:
				add_child(object)
			object.global_transform = save.exterior_object_info[new_object]
			
		for index in save.trees:
			var new_tree = GENERIC_TREE.instantiate()
			new_tree.selected_tree = index[0]
			main_island_nav_mesh.add_child(new_tree)
			new_tree.global_position = index[1]
		
		BuildManager.interior_objects = save.interior_object_info
		BuildManager.exterior_objects = save.exterior_object_info
		EventBus.current_trees = save.trees


func generate_save_file_id() -> String:
	var id : String
	var random_letter_int : int = len(characters)
	for i in range(4):
		id += characters[randi()%random_letter_int]
	return id

## Used for the player's navigtion, it's needed to reference a clean nav mesh
func load_player_nav_refrence_island(island : String):
	var i
	match island:
		"Island 1":
			i = PLAYER_NAV_BOUNDRY.instantiate()
	
	#i.visible = false
	get_tree().root.add_child.call_deferred(i)
	#await get_tree().create_timer(1).timeout
	#i.queue_free()

func trigger_save_fail_events():
	var scene = SAVE_DIDNT_LOAD.instantiate()
	world_environment.environment = BLACK_SKY
	sun.hide()
	EventBus.player.state =  EventBus.player.FREEZE_PLAYER
	inventory_interface.hide()
	EventBus.player.hide()
	add_child(scene)
	scene.global_position = EventBus.player.global_position

func send_nav_region_to_npcs():
	EventBus.send_nav_region.emit(navigation_mesh)

func spawn_trees():
	var save_objects = get_tree().get_nodes_in_group("SaveObject")
	var buildings = get_tree().get_nodes_in_group("Building")
	
	objects_to_avoid.append_array(save_objects)
	objects_to_avoid.append_array(buildings)

	for i in range(40):
		var spawn_point : Vector3 = await get_random_point_on_nav_mesh()
		
		if !is_too_close(spawn_point, objects_to_avoid):
			var new_tree = GENERIC_TREE.instantiate()
			main_island_nav_mesh.add_child(new_tree)
			new_tree.global_position = spawn_point
			objects_to_avoid.append(new_tree)

func spawn_stones():
	# Allows objects_to_avoid to be filled first
	await get_tree().create_timer(0.2).timeout
	for i in range(10):
		var spawn_point : Vector3 = await get_random_point_on_nav_mesh()
		
		if !is_too_close(spawn_point, objects_to_avoid):
			var slot_data : SlotData = SlotData.new()
			var new_stone = PICK_UP.instantiate()
			slot_data.item_data = STONE_ITEM
			new_stone.slot_data = slot_data
			add_child(new_stone)
			new_stone.label_3d.text = STONE_ITEM.name
			new_stone.global_position = spawn_point
			objects_to_avoid.append(new_stone)

func spawn_new_npc_house():
	BuildManager

func get_random_point_on_nav_mesh() -> Vector3:
	await get_tree().process_frame
	var random_point : Vector3
	
	if EventBus.tree_nav_mesh:
		map_rid = EventBus.tree_nav_mesh.get_region_rid()
		random_point = NavigationServer3D.region_get_random_point(map_rid, 2, false)
	
	return random_point


func is_too_close(new_point : Vector3, world_objects : Array) -> bool:
	for point in world_objects:
		if new_point.distance_to(point.global_position) < min_distance:
			return true
	return false

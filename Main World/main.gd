extends Node3D
# Set Roughness value to 0.5 and Normal to 0.1
######## ADD PIANO THAT PLAYS SONGS YOU RECORDED #####################
const PICK_UP = preload("uid://c8p87t4ex6hyc")
const TOM_NOOK = preload("uid://dhvnwgofhxw1i")
const GENERIC_TREE = preload("uid://dc2iy76lfy0ow")

##### NPC House
const NPC_HOUSE = preload("uid://wkpv6yfvw85n")

### Spawmed if save didn't load ###
const SAVE_DIDNT_LOAD = preload("uid://dlk1501txn687")
const BLACK_SKY = preload("uid://dxvl6jpkjyy33")

#### Item data resources #####
const STONE_ITEM = preload("uid://801bd84rk176")

#### Islands
const ISLAND_1 = preload("uid://c1sfbvd3rjb32")
const ISLAND_2 = preload("uid://cyrmqtrfwoaa0")

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/InventoryInterface/HotBarInventory
@onready var main_island_nav_mesh: NavigationRegion3D = $MainIslandNavMesh
@onready var world_environment: WorldEnvironment = $Sky/WorldEnvironment
@onready var sun: DirectionalLight3D = $Sky/Sun
@onready var island_node: Node3D = $MainIslandNavMesh/IslandNode
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
var can_trigger_fade_in : bool = true
var tom

func _ready() -> void:
	EventBus.player.toggle_inventory.connect(toggle_inventory_interface)
	EventBus.bake_nav_mesh.connect(bake_nav_mesh)
	EventBus.save_game_data.connect(save_game_data)
	EventBus.load_game_data.connect(load_game_data)
	EventBus.remove_tom_and_free_player.connect(remove_tom_and_free_player)
	hot_bar_inventory.send_held_slot_data.connect(EventBus.player.set_item_in_hand)
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)
	connect_toggle_external_inventory_signal()
	send_nav_region_to_npcs()
	BuildManager.build_camera = build_camera
	BuildManager.transition_camera = transition_camera
	BuildManager.speed = 10.0 # For build camera movement speed
	EventBus.is_in_player_house = false
	EventBus.is_in_overworld = true
	EventBus.current_trees.clear()
	if EventBus.game_is_new_save:
		if EventBus.game_state == EventBus.INTRO:
			init_new_savegame_events()
		else:
			EventBus.player.allow_gravity = true
	else:
		EventBus.game_state = EventBus.PLAY
		load_game_data()
		if BuildManager.home_can_upgrade:
			BuildManager.upgrade_home()
	
	load_island()
	spawn_stones()
	bake_nav_mesh()

func init_new_savegame_events():
	var tom_spawn_position : Vector3
	var player_spawn_position : Vector3
	var player_secondary_position : Vector3
	var npc_dialgue = NpcDialogue.new()
	var speech_data = npc_dialgue.get_correct_dialogue("Tom Intro", 0)
	inventory_interface.hide()
	
	await get_tree().process_frame #  Allows the island and town hall to spawn
	for building in get_tree().get_nodes_in_group("Building"):
		if building.has_meta("Intro"):
			tom_spawn_position = building.return_tom_spawn_point()
			player_spawn_position = building.return_player_spawn_point()
			player_secondary_position = building.return_player_secondary_point()
			
	tom = TOM_NOOK.instantiate()
	tom.global_position = tom_spawn_position
	add_child(tom)
	EventBus.player.toggle_collisions(2, false)
	EventBus.player.global_position = player_spawn_position
	EventBus.player.player_secondary_position = player_secondary_position
	await get_tree().create_timer(5).timeout
	EventBus.player.trigger_intro_sequence()
	await get_tree().create_timer(1.2).timeout
	EventBus.player.state = EventBus.player.INTRO_SEQUENCE
	await get_tree().create_timer(2).timeout
	EventBus.player.state = EventBus.player.FREEZE_PLAYER
	EventBus.display_speech_bubble.emit(speech_data[0], speech_data[1], speech_data[2], speech_data[3])

func remove_tom_and_free_player():
	tom.queue_free()
	await get_tree().create_timer(2).timeout
	EventBus.player.state = EventBus.player.IDLE
	EventBus.player.toggle_collisions(2, true)
	EventBus.player.allow_gravity = true
	
	var tween : Tween = get_tree().create_tween()
	inventory_interface.global_position.y = 120
	inventory_interface.show()
	tween.tween_property(inventory_interface, "global_position:y", 0.0, 0.5)

func _on_main_island_nav_mesh_bake_finished() -> void:
	if EventBus.game_is_new_save:
		spawn_trees()
	
	if can_trigger_fade_in:
		can_trigger_fade_in = false
		trigger_fade()

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
	EventBus.toggle_fade.emit(false)

func bake_nav_mesh():
	# Allows objects to spawn first before baking the nav mesh
	await get_tree().create_timer(0.5).timeout
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
	
	## This loop is for NPC's houses
	for node in get_tree().get_nodes_in_group("NPCStructure"):
		save.npc_houses[node.name] = node.house_data
	
	## If array is less that 3, player pos wasn't appened but if it was, overwrite that index
	if EventBus.player_customisations.size() < 4:
		EventBus.player_customisations.append(EventBus.player.global_position)
	else:
		EventBus.player_customisations[3] = EventBus.player.global_position
	
	BuildManager.exterior_objects = save.exterior_object_info
	save.interior_object_info = BuildManager.interior_objects
	EventBus.npc_houses = save.npc_houses
	
	save.inventory = EventBus.player.inventory_data
	save.hotbar_inventory = EventBus.player.hotbar_inventory_data
	save.player_balance = EventBus.player_balance
	save.savings_balance = EventBus.savings_balance
	save.loan_balance = EventBus.loan_balance
	save.player_data = EventBus.player_customisations
	save.previous_loan_balance = EventBus.previous_loan_balance
	save.player_is_debt_free = EventBus.player_is_debt_free
	save.house_level = EventBus.house_level
	save.trees = EventBus.current_trees
	save.world_time = EventBus.world_time
	save.selected_island_info = EventBus.selected_island_info
	
	
	if EventBus.game_is_new_save:
		EventBus.game_is_new_save = false
		EventBus.current_save_file_id = generate_save_file_id()
	
	save.write_savegame_data(EventBus.current_save_file_id)

func load_game_data():
	if SaveGame.save_exists(EventBus.current_save_file_id) == true:
		load_player_data()
		load_object_data()
		EventBus.player.allow_gravity = true
		EventBus.player.toggle_collisions(2, true)

func load_player_data():
	if EventBus.current_save_file_id:
		save = SaveGame.load_savegame_data(EventBus.current_save_file_id)
		EventBus.player.inventory_data.slot_datas = save.inventory.slot_datas
		EventBus.player.hotbar_inventory_data.slot_datas = save.hotbar_inventory.slot_datas
		EventBus.player_balance = save.player_balance
		EventBus.savings_balance = save.savings_balance
		EventBus.loan_balance = save.loan_balance
		EventBus.player_customisations = save.player_data
		EventBus.previous_loan_balance = save.previous_loan_balance
		EventBus.player_is_debt_free = save.player_is_debt_free
		EventBus.house_level = save.house_level
		EventBus.selected_island_info = save.selected_island_info
		inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
		inventory_interface.set_player_hot_bar_inventory(EventBus.player.hotbar_inventory_data)

func load_object_data():
	if EventBus.current_save_file_id:
		save = SaveGame.load_savegame_data(EventBus.current_save_file_id)
		var object
		for new_object in save.exterior_object_info:
			#print("New Object : ", new_object)
			var current_new_object
			if new_object == "Tent":
				if EventBus.house_level == 1:
					current_new_object = "Player House"
				else:
					current_new_object = new_object
			else:
				current_new_object = new_object
			
			#print("Current new object : ", current_new_object)
			BuildManager.current_object_name_to_spawn = current_new_object
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
		
		for key in save.npc_houses:
			var new_house = NPC_HOUSE.instantiate()
			new_house.house_data = save.npc_houses[key]
			main_island_nav_mesh.add_child(new_house, true)
			new_house.global_transform = save.npc_houses[key][0]
		
		BuildManager.interior_objects = save.interior_object_info
		BuildManager.exterior_objects = save.exterior_object_info
		EventBus.current_trees = save.trees
		EventBus.npc_houses = save.npc_houses


func generate_save_file_id() -> String:
	var id : String
	var random_letter_int : int = len(characters)
	for i in range(4):
		id += characters[randi()%random_letter_int]
	return id

## Used for the player's navigtion, it's needed to reference a clean nav mesh
func load_island():
	var island_name
	var island
	
	if EventBus.selected_island_info.is_empty():
		island_name = "Island 1"
	else:
		island_name = EventBus.selected_island_info[0]
	
	match island_name:
		"Island 1":
			island_node.global_position.y = -1.145
			island = ISLAND_1.instantiate()
		"Island 2":
			island_node.global_position.y = -12.555
			island = ISLAND_2.instantiate()
	
	island_node.add_child.call_deferred(island)

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
	pass

func get_random_point_on_nav_mesh() -> Vector3:
	await get_tree().process_frame
	var random_point : Vector3
	
	if EventBus.tree_nav_mesh:
		map_rid = EventBus.tree_nav_mesh.get_rid()
		random_point = NavigationServer3D.region_get_random_point(map_rid, 2, false)
	
	return random_point


func is_too_close(new_point : Vector3, world_objects : Array) -> bool:
	for point in world_objects:
		if point:
			if new_point.distance_to(point.global_position) < min_distance:
				return true
	return false

extends CharacterBody3D

signal toggle_inventory
signal toggle_pause
signal save_outside_data
signal save_player_data

@export var inventory_data : InventoryData
@export var hotbar_inventory_data : InventoryData

@export var skin_colour : Color
@export var held_items : Dictionary[String, PackedScene]
@export var forced_rotation_y : float = 0.0
@export var is_entering_building : bool = true
@export var should_force_rotation_for_entry : bool = true
@export var mainland_nav_mesh : NavigationRegion3D
@onready var skeleton_3d: Skeleton3D = $PlayerNode/Armature/Skeleton3D
@onready var eyes_mesh_setter: Node3D = $EyesMeshSetter
@onready var mouth_mesh_setter: Node3D = $MouthMeshSetter
@onready var animation_player: AnimationPlayer = $PlayerNode/AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var player_node: Node3D = $PlayerNode
@onready var item_drop_point: Marker3D = $PlayerNode/ItemDropPoint
@onready var hand_item_spawn: Node3D = $PlayerNode/Armature/Skeleton3D/ModifierBoneTarget3D/HandItemSpawn
@onready var shape_cast_3d: ShapeCast3D = $PlayerNode/ShapeCast3D
@onready var camera_3d: Camera3D = $CameraPivotPoint/Camera3D
@onready var doorway_entry_anim: AnimationPlayer = $DoorwayEntryAnim
@onready var object_drop_point: Marker3D = $PlayerNode/ObjectDropPoint
@onready var ground_detection_raycasts: Node3D = $PlayerNode/ObjectDropPoint/GroundDetectionRaycasts

var speed = 80.0 #30.0
var direction = Vector3.ZERO
var acceleration = 10.0
var air_speed = 60.0 #22.0
var jumpforce = 40.0
var gravity = 80.0
var state
var anim_speed : float = 1.0
var allow_gravity : bool = true
var scene_change_fade_called : bool = false
var doorway_events_can_trigger : bool = false
var raycasted_door_found : StaticBody3D
var map_rid : RID
var edge_push_strength : float = 50.0

enum {
	IDLE,
	WALK,
	RUN,
	ACTION,
	ENTER_DOOR,
	FREEZE_PLAYER,
	RE_ENTER_OVERWORLD
}

func _ready() -> void:
	EventBus.player = self
	state = IDLE
	set_skin_colour(skin_colour)
	disable_and_enable_nav_mesh_limit()
	if mainland_nav_mesh:
		map_rid = mainland_nav_mesh.get_navigation_map()
	if EventBus.trigger_building_exit_event:
		state = RE_ENTER_OVERWORLD
		EventBus.trigger_building_exit_event = false
	if doorway_events_can_trigger == false:
		doorway_events_can_trigger = true

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backwards")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), acceleration * delta)

	match state:
		IDLE:
			idle(input_dir)
		WALK:
			move_player(delta, direction, input_dir)
		RUN:
			pass
		ACTION:
			do_action()
		ENTER_DOOR:
			enter_door()
		FREEZE_PLAYER:
			pass
		RE_ENTER_OVERWORLD:
			leave_building_doorway()
	
	animation_tree.advance(delta * anim_speed)
	detect_raycast_collision()
	is_player_on_nav_mesh(delta)
	#jump()
	apply_gravity(delta)
	move_and_slide()

func disable_and_enable_nav_mesh_limit():
	await get_tree().create_timer(0.2).timeout
	EventBus.player_can_leave_nav_mesh = false

func idle(input_dir):
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Idle")
	EventBus.update_clothes_anim.emit("Idle", anim_speed)
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.z = move_toward(velocity.z, 0, speed)
	
	if input_dir:
		state = WALK
	
	if Input.is_action_just_pressed("use tool") and EventBus.held_item_slot_data:
		# Need to specify what item can be swung!!!!!
		state = ACTION

func move_player(delta, _direction, input_dir):
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Walk")
	EventBus.update_clothes_anim.emit("Walk", anim_speed)
	if is_on_floor():
		if direction :
			velocity.x = _direction.x * speed
			velocity.z = _direction.z * speed
		#else:
			#velocity.x = move_toward(velocity.x, 0, speed)
			#velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = direction.x * air_speed
		velocity.z = direction.z * air_speed
	
	if input_dir == Vector2.ZERO:
		state = IDLE
	
	player_node.rotation.y = lerp_angle(player_node.rotation.y, atan2(velocity.x, velocity.z) - rotation.y, delta * 10)

func do_action():
	anim_speed = 2.0
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Action")
	EventBus.update_clothes_anim.emit("Action", anim_speed)

func enter_door():
	if doorway_events_can_trigger:
		doorway_events_can_trigger = false
		velocity = Vector3.ZERO
		anim_speed = 1.0
		allow_gravity = false
		var anim_state = animation_tree.get("parameters/playback")
		anim_state.travel("Walk")
		EventBus.update_clothes_anim.emit("Walk", anim_speed)
		if should_force_rotation_for_entry:
			#Makes player face forward
			forced_rotation_y = 180 if player_node.rotation.y > 0 else -180.0
			is_entering_building = true
		else:
			# if not walk forward change walk direction
			is_entering_building = false
		
		
		if is_entering_building and !EventBus.trigger_building_exit_event:
			doorway_entry_anim.play("Enter Building")
		else:
			doorway_entry_anim.play("Leave Building")
		forced_rotation_y = deg_to_rad(forced_rotation_y)
		player_node.rotation.y = lerp_angle(player_node.rotation.y, forced_rotation_y, 0.25)
		camera_3d.top_level = true
		await get_tree().create_timer(2.1).timeout # Move player for 2 secs
		state = FREEZE_PLAYER
		if !scene_change_fade_called:
			FadeCanvasLayer.trigger_scene_change_fade(true)
			scene_change_fade_called =  true
		
		await get_tree().create_timer(2).timeout # wait then transition scene
		
		if EventBus.is_in_overworld:
			get_tree().change_scene_to_file("res://Room/room.tscn")
		else:
			get_tree().change_scene_to_file("res://Main World/main.tscn")

func leave_building_doorway():
	if doorway_events_can_trigger:
		EventBus.player_can_leave_nav_mesh = true
		toggle_collisions(2, false)
		allow_gravity = false
		global_position = EventBus.last_building_entered["building pos"]
		doorway_events_can_trigger = false
		await get_tree().create_timer(2).timeout
		if raycasted_door_found:
			raycasted_door_found.play_anim()
		await get_tree().create_timer(1).timeout
		var anim_state = animation_tree.get("parameters/playback")
		anim_state.travel("Walk")
		EventBus.update_clothes_anim.emit("Walk", anim_speed)
		#EventBus.last_building_entered["building node"].play_anim()
		doorway_entry_anim.play("Leave Building")
		await get_tree().create_timer(1.5).timeout
		doorway_entry_anim.stop()
		velocity = Vector3.ZERO
		state = IDLE
		allow_gravity = true
		toggle_collisions(2, true)

func exit_state():
	anim_speed = 1.0
	state = IDLE

func jump():
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y += jumpforce

func apply_gravity(delta):
	if allow_gravity:
		if not is_on_floor():
			velocity.y -= gravity * delta

func set_skin_colour(colour : Color):
	var material_override = StandardMaterial3D.new()
	material_override.albedo_color = colour
	material_override.roughness = 0.5
	material_override.normal_enabled = true
	material_override.normal_scale = 0.1
	
	#var mat = body__m_eye.mesh.surface_get_material(0)
	#mat.albedo_color = colour
	for node in skeleton_3d.get_children():
		if !node.name == "Nose00__mNose" and !node.name == "Nose01__mNose" and !node.name == "Nose02__mNose" and !node.name == "Body__mEye" and !node.name == "Body__mMouth" and !node.name == "ModifierBoneTarget3D" and !node.name == "Hair":
			node.set_surface_override_material(0, material_override)
	
	eyes_mesh_setter.set_body_part_colour(colour)
	mouth_mesh_setter.set_body_part_colour(colour)

func eat_consumable():
	pass

func use_slot_data(slot_data : SlotData, inventory_data : InventoryData, slot_index : int):
	if slot_data.item_data is ItemDataPositioning:
		toggle_ground_raycasts(true)
		await get_tree().create_timer(0.1).timeout
		check_ground_raycast_collisions()
		BuildManager.current_object_name_to_spawn = slot_data.item_data.name
		BuildManager.object_spawn_position = Vector3(object_drop_point.global_position.x, 16.0, object_drop_point.global_position.z)
		BuildManager.trigger_confirm_message_for_building()
		BuildManager.item_to_remove_inventory_data = inventory_data
		BuildManager.item_to_remove_slot_index = slot_index
		toggle_ground_raycasts(false)

func toggle_ground_raycasts(value : bool):
	for ray in ground_detection_raycasts.get_children():
		ray.enabled = value

func check_ground_raycast_collisions():
	var raycasts_that_are_colliding : Array = [false, false, false, false]
	var index : int = 0
	for ray in ground_detection_raycasts.get_children():
		if ray.is_colliding():
			raycasts_that_are_colliding[index] = true
			index += 1
	
	if raycasts_that_are_colliding.has(false):
		BuildManager.all_ground_ray_casts_collide = false
	else:
		BuildManager.all_ground_ray_casts_collide = true

func get_drop_point() -> Vector3:
	return item_drop_point.global_position

func set_item_in_hand(slot_data):
	# this is broken
	var current_held_item = hand_item_spawn.get_children()
	if current_held_item:
		for child in current_held_item:
			child.queue_free()
	
	if slot_data:
		var item_name = slot_data.item_data.name
		var item = held_items[item_name].instantiate()
		hand_item_spawn.add_child(item)
		#item.global_rotation.x = hand_item_spawn.global_rotation.x
		#item.global_rotation.y = hand_item_spawn.global_rotation.y

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Inventory"):
		toggle_inventory.emit()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Swing/swing":
		exit_state()

func detect_raycast_collision():
	if shape_cast_3d.is_colliding():
		var collider = shape_cast_3d.get_collider(0)
		if collider.is_in_group("Door"):
			raycasted_door_found = collider
			print("Set raycasted door")
			if Input.is_action_just_pressed("Interact"):
				doorway_events_can_trigger = true
				toggle_collisions(2, false)
				EventBus.last_building_entered["building pos"] = collider.return_spawn_point()
				EventBus.last_building_entered["building node"] = collider
				state = ENTER_DOOR
				collider.play_anim()
		if collider.is_in_group("ThisNPCTalks"):
			if Input.is_action_just_pressed("Interact"):
				collider.speak_to_player()

func is_player_on_nav_mesh(delta : float):
	# All this prevents the player from falling off the edges of rivers and such
	if !EventBus.player_can_leave_nav_mesh and EventBus.is_in_overworld:
		var player_pos = global_position
		var closest_nav_point = NavigationServer3D.map_get_closest_point(map_rid, player_pos)
		var distance = player_pos.distance_to(closest_nav_point)
		
		if distance > 0.9:
			global_position = lerp(global_position, closest_nav_point, 0.3)

func toggle_collisions(layer_value : int, bool_value : bool):
	set_collision_mask_value(layer_value, bool_value)


func _on_doorway_entry_anim_animation_finished(_anim_name: StringName) -> void:
	global_position = player_node.global_position


func _on_collision_checker_body_entered(body: Node3D) -> void:
	BuildManager.colliding_with_another_object = true


func _on_collision_checker_body_exited(body: Node3D) -> void:
	BuildManager.colliding_with_another_object = false

func toggle_camera_zoom_in():
	pass

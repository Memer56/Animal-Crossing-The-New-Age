extends CharacterBody3D

signal toggle_inventory
signal toggle_pause
signal save_outside_data
signal save_player_data

@export var inventory_data : InventoryData
@export var hotbar_inventory_data : InventoryData
@export var skin_colour : Color
@export var held_items : Dictionary[String, PackedScene]
@export var footstep_audio : Array[AudioStreamOggVorbis]
@export var forced_rotation_y : float = 0.0
@export var is_entering_building : bool = true
@export var should_force_rotation_for_entry : bool = true

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
@onready var item_ground_raycasts: Node3D = $PlayerNode/ItemDropPoint/ItemGroundRaycasts
@onready var item_collision_checker: Area3D = $PlayerNode/ItemDropPoint/ItemCollisionChecker
@onready var collision_checker: Area3D = $PlayerNode/ObjectDropPoint/CollisionChecker
@onready var hair__m_hair: MeshInstance3D = $PlayerNode/Armature/Skeleton3D/Hair/HairPosNode/Armature/Skeleton3D/Hair__mHair
@onready var ledge_detector: RayCast3D = $PlayerNode/LedgeDetector
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var speed = 80.0 #30.0
var direction = Vector3.ZERO
var acceleration = 10.0
var air_speed = 60.0 #22.0
var jumpforce = 40.0
var gravity = 80.0
var state
var anim_speed : float = 1.0
var allow_gravity : bool = false
var scene_change_fade_called : bool = false
var doorway_events_can_trigger : bool = false
var raycasted_door_found : StaticBody3D
var map_rid : RID
var edge_push_strength : float = 50.0
var doorway_is_airport : bool = false
var player_secondary_position : Vector3

enum {
	IDLE,
	WALK,
	RUN,
	ACTION,
	ENTER_DOOR,
	FREEZE_PLAYER,
	RE_ENTER_OVERWORLD,
	INTRO_SEQUENCE
}

func _ready() -> void:
	EventBus.player = self
	state = IDLE
	BuildManager.camera = camera_3d
	if EventBus.trigger_building_exit_event:
		state = RE_ENTER_OVERWORLD
		EventBus.trigger_building_exit_event = false

	if doorway_events_can_trigger == false:
		doorway_events_can_trigger = true
	
	await get_tree().create_timer(0.1).timeout
	set_skin_colour()
	set_hair_colour()
	set_player_position()

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backwards")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), acceleration * delta)
	
	if Input.get_connected_joypads() and !EventBus.controller_found:
		EventBus.controller_found = true
		Input.set_joy_light(0, Color(0.964, 0.89, 0.353, 1.0))
	else:
		EventBus.controller_found = false
	
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
			var anim_state = animation_tree.get("parameters/playback")
			anim_state.travel("Idle")
			EventBus.update_clothes_anim.emit("Idle", anim_speed)
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
		RE_ENTER_OVERWORLD:
			leave_building_doorway()
		INTRO_SEQUENCE:
			trigger_intro_sequence()
	
	animation_tree.advance(delta * anim_speed)
	detect_raycast_collision()
	
	if EventBus.is_in_overworld:
		is_player_on_land()

	apply_gravity(delta)
	move_and_slide()

func set_player_position():
	if EventBus.is_in_overworld:
		if !EventBus.player_customisations.is_empty():
			if EventBus.player_customisations.size() > 3:
				global_position = EventBus.player_customisations[3]

func idle(input_dir):
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Idle")
	EventBus.update_clothes_anim.emit("Idle", anim_speed)
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.z = move_toward(velocity.z, 0, speed)
	
	if input_dir:
		state = WALK
	
	#if Input.is_action_just_pressed("use tool") and EventBus.held_item_slot_data:
		#if EventBus.held_item_slot_data.item_data.can_do_action:
			#if EventBus.held_item_slot_data.item_data.item_type == 0: # Axe
				#pass
			#state = ACTION

func move_player(delta, _direction, input_dir):
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Walk")
	EventBus.update_clothes_anim.emit("Walk", anim_speed)
	if is_on_floor():
		if direction :
			velocity.x = _direction.x * speed
			velocity.z = _direction.z * speed
			play_footsteps()
		#else:
			#velocity.x = move_toward(velocity.x, 0, speed)
			#velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = direction.x * air_speed
		velocity.z = direction.z * air_speed
	
	if input_dir == Vector2.ZERO:
		state = IDLE
	
	player_node.rotation.y = lerp_angle(player_node.rotation.y, atan2(velocity.x, velocity.z) - rotation.y, delta * 10)

func play_footsteps():
	if audio_stream_player.playing == false:
		var random_index : int = randi_range(0, 9)
		audio_stream_player.stream = footstep_audio[random_index]
		audio_stream_player.pitch_scale = randf_range(0.8, 1.1)
		audio_stream_player.play()

func do_action():
	anim_speed = 2.0
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Action")
	EventBus.update_clothes_anim.emit("Action", anim_speed)

func enter_door():
	if doorway_events_can_trigger:
		velocity = Vector3.ZERO
		anim_speed = 1.0
		allow_gravity = false
		var anim_state = animation_tree.get("parameters/playback")
		anim_state.travel("Walk")
		EventBus.update_clothes_anim.emit("Walk", anim_speed)
		EventBus.save_game_data.emit()
		
		if should_force_rotation_for_entry:
			#Makes player face forward or angled
			if doorway_is_airport:
				forced_rotation_y = 130
			else:
				forced_rotation_y = 180 if player_node.rotation.y > 0 else -180.0
			
			is_entering_building = true
		else:
			# if not walk forward change walk direction
			is_entering_building = false
		
		
		if is_entering_building and !EventBus.trigger_building_exit_event:
			if doorway_is_airport:
				doorway_entry_anim.play("Enter Airport")
			else:
				doorway_entry_anim.play("Enter Building")
		else:
			if doorway_is_airport:
				doorway_entry_anim.play("Exit Airport")
			else:
				doorway_entry_anim.play("Leave Building")
		
		player_node.rotation.y = lerp_angle(player_node.rotation.y, deg_to_rad(forced_rotation_y), 0.25)
		camera_3d.top_level = true
		await get_tree().create_timer(2.1).timeout # Move player for 2 secs
		state = FREEZE_PLAYER
		doorway_events_can_trigger = false
		
		if !scene_change_fade_called:
			EventBus.toggle_fade.emit(true)
			scene_change_fade_called =  true
		
		await get_tree().create_timer(2).timeout # wait then transition scene
		
		if EventBus.is_in_overworld:
			get_tree().change_scene_to_file.call_deferred("res://Room/room.tscn")
		else:
			get_tree().change_scene_to_file.call_deferred("res://Main World/main.tscn")

func leave_building_doorway():
	if doorway_events_can_trigger:
		toggle_collisions(2, false)
		allow_gravity = false
		global_position = EventBus.last_building_entered["building pos"]
		doorway_events_can_trigger = false
		await get_tree().create_timer(2).timeout
		if raycasted_door_found:
			if raycasted_door_found.has_meta("Airport"):
				raycasted_door_found.send_room_to_event_bus()
				# I dont know why this has to be -160 degrees you'd think it'd be -45
				player_node.rotation.y = lerp_angle(player_node.rotation.y, deg_to_rad(-160), 0.25)
			else:
				raycasted_door_found.play_anim()
		await get_tree().create_timer(1).timeout
		var anim_state = animation_tree.get("parameters/playback")
		anim_state.travel("Walk")
		EventBus.update_clothes_anim.emit("Walk", anim_speed)
		#EventBus.last_building_entered["building node"].play_anim()
		if raycasted_door_found.has_meta("Airport"):
			doorway_entry_anim.play("Exit Airport")
		else:
			doorway_entry_anim.play("Leave Building")
		await get_tree().create_timer(1.5).timeout
		global_position = player_node.global_position
		doorway_entry_anim.stop()
		velocity = Vector3.ZERO
		state = IDLE
		allow_gravity = true
		toggle_collisions(2, true)

func trigger_intro_sequence():
	player_node.rotation.y = lerp_angle(player_node.rotation.y, deg_to_rad(-160), 0.25)
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Walk")
	EventBus.update_clothes_anim.emit("Walk", anim_speed)
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", player_secondary_position, 2)

func update_root_to_real_position():
	print("Moving root to player_node")
	global_position = lerp(global_position, player_node.global_position, 0.25)

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

func set_skin_colour():
	var new_colour : Color
	var material_override = StandardMaterial3D.new()
	
	if EventBus.player_customisations.is_empty():
		new_colour = skin_colour
	else:
		new_colour = EventBus.player_customisations[1]
	
	material_override.albedo_color = new_colour
	material_override.roughness = 0.5
	material_override.normal_enabled = true
	material_override.normal_scale = 0.1
	
	#var mat = body__m_eye.mesh.surface_get_material(0)
	#mat.albedo_color = colour
	for node in skeleton_3d.get_children():
		if !node.name == "Nose00__mNose" and !node.name == "Nose01__mNose" and !node.name == "Nose02__mNose" and !node.name == "Body__mEye" and !node.name == "Body__mMouth" and !node.name == "ModifierBoneTarget3D" and !node.name == "Hair":
			node.set_surface_override_material(0, material_override)
	
	eyes_mesh_setter.set_body_part_colour(new_colour)
	mouth_mesh_setter.set_body_part_colour(new_colour)

func set_hair_colour():
	var new_colour : Color
	var material_override : StandardMaterial3D = hair__m_hair.get_surface_override_material(0)
	
	if EventBus.player_customisations.is_empty():
		new_colour = Color("b794fe")
	else:
		new_colour = EventBus.player_customisations[2]
	
	material_override.albedo_color = new_colour

func eat_consumable():
	pass

func use_slot_data(slot_data : SlotData, inventory_data : InventoryData, slot_index : int):
	if slot_data.item_data is ItemDataPositioning:
		var spawn_point : Marker3D
		var raycast_variable : bool
		var y_spawn_pos : float

		if slot_data.item_data.item_type == 1: # Building type
			spawn_point = object_drop_point
			raycast_variable = true
			collision_checker.call_deferred("set_monitoring", true)
			item_collision_checker.call_deferred("set_monitoring", false)
		elif slot_data.item_data.item_type == 0: # Furniture and stuff
			spawn_point = item_drop_point
			raycast_variable = false
			item_collision_checker.call_deferred("set_monitoring", true)
			collision_checker.call_deferred("set_monitoring", false)
		
		if EventBus.is_in_overworld:
			y_spawn_pos = 16.0
		else:
			y_spawn_pos = 0.0
		
		toggle_ground_raycasts(true, raycast_variable)
		await get_tree().create_timer(0.1).timeout
		check_ground_raycast_collisions(raycast_variable)
		BuildManager.current_object_name_to_spawn = slot_data.item_data.name
		BuildManager.object_spawn_position = Vector3(spawn_point.global_position.x, y_spawn_pos, spawn_point.global_position.z)
		BuildManager.item_to_remove_inventory_data = inventory_data
		BuildManager.item_to_remove_slot_index = slot_index
		toggle_ground_raycasts(false, raycast_variable)
		EventBus.trigger_confirm_message.emit("Would you like to place this here?")

func toggle_ground_raycasts(value : bool, is_building_object : bool):
	var raycasts
	if is_building_object:
		raycasts = ground_detection_raycasts
	else:
		raycasts = item_ground_raycasts
	
	for ray in raycasts.get_children():
		ray.enabled = value

func check_ground_raycast_collisions(is_building_object : bool):
	var raycasts_that_are_colliding : Array = [false, false, false, false]
	var index : int = 0
	var raycast
	
	if is_building_object:
		raycast = ground_detection_raycasts
	else:
		raycast = item_ground_raycasts
	
	for ray in raycast.get_children():
		if ray.is_colliding():
			raycasts_that_are_colliding[index] = true
			index += 1
	
	if raycasts_that_are_colliding.has(false):
		BuildManager.all_ground_ray_casts_collide = false
	else:
		BuildManager.all_ground_ray_casts_collide = true

func get_drop_point() -> Vector3:
	return item_drop_point.global_position

func set_item_in_hand(slot_data : SlotData):
	# this is broken
	var current_held_item = hand_item_spawn.get_children()
	if current_held_item:
		for child in current_held_item:
			child.queue_free()
	
	if slot_data and slot_data.item_data.can_display_in_hand:
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
		if collider:
			if collider.is_in_group("Door"):
				raycasted_door_found = collider
				if Input.is_action_just_pressed("Interact"):
					if !EventBus.service_buildings_closed:
						if collider.has_meta("Airport"):
							doorway_is_airport = true
							collider.send_room_to_event_bus()
						else:
							collider.play_anim()
						doorway_events_can_trigger = true
						toggle_collisions(2, false)
						EventBus.last_building_entered["building pos"] = collider.return_spawn_point()
						EventBus.last_building_entered["building node"] = collider
						state = ENTER_DOOR
						
			
			if collider.is_in_group("ThisNPCTalks"):
				if Input.is_action_just_pressed("Interact"):
					collider.speak_to_player()
			
			if collider.is_in_group("CanBePickedUp"):
				if Input.is_action_just_pressed("Interact"):
					if !collider.disable_interaction:
						collider.add_self_to_player_inventory()
						if EventBus.is_in_overworld:
							BuildManager.exterior_objects.erase(collider.self_slot_data.item_data.name)
						else:
							BuildManager.interior_objects.erase(collider.self_slot_data.item_data.name)
				
				if Input.is_action_pressed("ChangeObjectTransform"):
					if Input.is_action_just_pressed("MouseWheelDown"):
						collider.rotate_self(90.0)
					elif Input.is_action_just_pressed("MouseWheelUp"):
						collider.rotate_self(-90.0)
			
			if collider.is_in_group("ATM"):
				if Input.is_action_just_pressed("Interact"):
					EventBus.toggle_atm_ui.emit()
			
			if collider.is_in_group("ShopObject"):
				if Input.is_action_just_pressed("Interact"):
					collider.display_object_information()
			
			if collider.is_in_group("ItemCanBeToggled"):
				if Input.is_action_just_pressed("ToggleItem"):
					collider.toggle_self()
			
			if collider.is_in_group("Crafting Table"):
				if Input.is_action_just_pressed("Interact"):
					EventBus.toggle_crafting_ui.emit()
			
			if collider.is_in_group("Chair"):
				if Input.is_action_just_pressed("Interact"):
					collider.trigger_dialogue()
			
			if collider.is_in_group("Destructable"):
				if Input.is_action_just_pressed("use tool") and EventBus.held_item_slot_data:
					if EventBus.held_item_slot_data.item_data.can_do_action:
						if EventBus.held_item_slot_data.item_data.item_type == 0:
							collider.damage_object(EventBus.held_item_slot_data)
						state = ACTION

func is_player_on_land():
	# All this prevents the player from falling off the edges of rivers and such
	if EventBus.is_in_overworld:
		
		if !ledge_detector.is_colliding():
			#global_position = lerp(global_position, player_pos, 0.3)
			velocity.x = 0.0
			velocity.z = 0.0

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


func _on_item_collision_checker_body_entered(body: Node3D) -> void:
	BuildManager.colliding_with_another_object = true


func _on_item_collision_checker_body_exited(body: Node3D) -> void:
	BuildManager.colliding_with_another_object = false

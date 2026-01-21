extends Node3D
# Camera has no limits, camera can leave playable area

# Objects/Items that can be placed
const SIMPLE_BED = preload("uid://c0ws7r3aiyogq")
const CURSED_ITEM = preload("uid://b2h3ug1uscfdj")

# Buildings that can spawn
const PLAYER_TENT = preload("uid://du1vi2sn7tjhm")

signal toggle_menu_ui
signal send_data_to_ui(slot_data : SlotData)

var object_spawn_position : Vector3
var current_object_name_to_spawn : String
var item_to_remove_inventory_data : InventoryData
var item_to_remove_slot_index : int
var all_ground_ray_casts_collide : bool = true
var colliding_with_another_object : bool = false
var camera : Camera3D
var build_camera : Camera3D
var transition_camera : Camera3D
var is_in_build_mode : bool = false
var speed = 10.0
var direction = Vector3.ZERO
var acceleration = 10.0
var camera_is_transitioning : bool = false
var current_selectable : Object
var allow_object_dragging : bool = false
var exterior_objects : Dictionary[String, Vector3]
var interior_objects : Dictionary[String, Vector3]

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backwards")
	direction = lerp(direction, (build_camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), acceleration * delta)
	
	if direction:
		build_camera.global_position.x += direction.x * speed
		build_camera.global_position.z += direction.z * speed
	
	if allow_object_dragging:
		drag_selected_object()


func spawn_object():
	var object = get_object_to_spawn()
	
	if verify_valid_placement():
		var node_to_place_object
		if EventBus.is_in_overworld:
			node_to_place_object = "Main/MainIslandNavMesh"
		else:
			node_to_place_object = "Room"
		get_tree().root.get_node(node_to_place_object).add_child(object)
		object.global_position = object_spawn_position
		remotely_remove_item(item_to_remove_inventory_data, item_to_remove_slot_index)
		if EventBus.is_in_overworld:
			EventBus.bake_nav_mesh.emit()
			exterior_objects[current_object_name_to_spawn] = object.global_position
		else:
			interior_objects[current_object_name_to_spawn] = object.global_position
	else:
		EventBus.display_speech_bubble.emit(["Sorry this can't be placed [color=red]here[/color]"], "Sorry!")

func get_object_to_spawn() -> Object:
	var object
	match current_object_name_to_spawn:
		###### Objects ######
		
		"Simple Bed":
			object = SIMPLE_BED.instantiate()
		"Cursed Item":
			object = CURSED_ITEM.instantiate()
		
		###### Buildings ######
		"Tent":
			object = PLAYER_TENT.instantiate()
	return object

func verify_valid_placement() -> bool:
	if all_ground_ray_casts_collide and !colliding_with_another_object:
		return true
	return false

func remotely_remove_item(inventory_data : InventoryData, slot_index : int):
	inventory_data.remove_item(slot_index, 1)

func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ToggleBuildMode"):
		toggle_build_mode()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("LMB"):
		if is_in_build_mode:
			select_object()
	
	if Input.is_action_pressed("LMB"):
		if is_in_build_mode:
			allow_object_dragging = true
	else:
		allow_object_dragging = false
	
	if Input.is_action_just_pressed("RMB"):
		if is_in_build_mode:
			deselect_object()
	
	if Input.is_action_just_released("MouseWheelUp"):
		rotate_current_selectable(-1)
	
	if Input.is_action_just_released("MouseWheelDown"):
		rotate_current_selectable(1)

func toggle_build_mode():
	if !camera_is_transitioning:
		camera_is_transitioning = true
		if is_in_build_mode:
			is_in_build_mode = false
			change_camera(camera)
			transition_camera.global_transform = build_camera.global_transform
			set_physics_process(false)
			EventBus.player.state = EventBus.player.IDLE
			deselect_object()
		else:
			is_in_build_mode = true
			change_camera(build_camera)
			transition_camera.global_transform = camera.global_transform
			set_physics_process(true)
			EventBus.player.state = EventBus.player.FREEZE_PLAYER
		toggle_menu_ui.emit()
		transition_camera.make_current()

func change_camera(desired_camera : Camera3D):
	var transition_tween : Tween = create_tween()
	var target_transform : Transform3D = desired_camera.global_transform
	transition_tween.tween_property(transition_camera, "global_transform", target_transform, 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.6).timeout
	desired_camera.make_current()
	camera_is_transitioning = false

func select_object():
	# For detecting objects, only collides with objects
	const RAY_LENGTH = 5000.0
	
	var mouse_position = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	var _camera = get_viewport().get_camera_3d()
	var ray_origin = _camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + _camera.project_ray_normal(mouse_position) * RAY_LENGTH
	
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))
	if result:
		var node = result.collider
		if node.has_meta("Selectable"):
			deselect_object()
			node.highlight_object()
			current_selectable = node
			send_data_to_ui.emit(current_selectable.self_slot_data)
			#current_selectable.position.x = round(result.position.x)
			#current_selectable.position.z = round(result.position.z)
		else:
			deselect_object()

func drag_selected_object():
	# For allowing objects to follw cursor, only collides with ground
	if current_selectable:
		const RAY_LENGTH = 5000.0
		
		var mouse_position = get_viewport().get_mouse_position()
		var space_state = get_world_3d().direct_space_state
		var _camera = get_viewport().get_camera_3d()
		var ray_origin = _camera.project_ray_origin(mouse_position)
		var ray_end = ray_origin + _camera.project_ray_normal(mouse_position) * RAY_LENGTH
		
		var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))
		if result:
			var node = result.collider
			if node.has_meta("Ground"):
				current_selectable.position.x = lerpf(current_selectable.position.x, result.position.x, 0.1)
				current_selectable.position.z = lerpf(current_selectable.position.z, result.position.z, 0.1)
				#current_selectable.position.x = result.position.x
				#current_selectable.position.z = result.position.z

func rotate_current_selectable(_direction : int):
	if current_selectable:
		current_selectable.rotate_y(deg_to_rad(-22.5 * _direction))

func deselect_object():
	if current_selectable:
		current_selectable.remove_object_highlight()
		current_selectable = null
		send_data_to_ui.emit(null)

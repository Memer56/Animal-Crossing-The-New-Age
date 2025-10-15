extends CharacterBody3D

signal toggle_inventory
signal toggle_pause
signal save_outside_data
signal save_player_data

@export var inventory_data : InventoryData
@export var hot_bar_inventory_data : InventoryData

@export var skin_colour : Color
@export var held_items : Dictionary[String, PackedScene]
@onready var skeleton_3d: Skeleton3D = $PlayerNode/Armature/Skeleton3D
@onready var eyes_mesh_setter: Node3D = $EyesMeshSetter
@onready var mouth_mesh_setter: Node3D = $MouthMeshSetter
@onready var animation_player: AnimationPlayer = $PlayerNode/AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var player_node: Node3D = $PlayerNode
@onready var item_drop_point: Marker3D = $PlayerNode/ItemDropPoint
@onready var hand_item_spawn: Node3D = $PlayerNode/Armature/Skeleton3D/ModifierBoneTarget3D/HandItemSpawn

var speed = 80.0 #30.0
var direction = Vector3.ZERO
var acceleration = 10.0
var air_speed = 60.0 #22.0
var jumpforce = 40.0
var gravity = 80.0
var state
var anim_speed : float = 1.0

enum {
	IDLE,
	WALK,
	RUN,
	ACTION
}

func _ready() -> void:
	EventBus.player = self
	state = IDLE
	set_skin_colour(skin_colour)

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
	
	animation_tree.advance(delta * anim_speed)
	jump()
	apply_gravity(delta)
	move_and_slide()

func idle(input_dir):
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Idle")
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.z = move_toward(velocity.z, 0, speed)
	
	if input_dir:
		state = WALK
	
	if Input.is_action_just_pressed("use tool") and EventBus.held_item_slot_data:
		state = ACTION

func move_player(delta, _direction, input_dir):
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel("Walk")
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

func exit_state():
	anim_speed = 1.0
	state = IDLE

func jump():
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y += jumpforce

func apply_gravity(delta):
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
		if !node.name == "Nose00__mNose" and !node.name == "Nose01__mNose" and !node.name == "Nose02__mNose" and !node.name == "Body__mEye" and !node.name == "Body__mMouth" and !node.name == "ModifierBoneTarget3D":
			node.set_surface_override_material(0, material_override)
	
	eyes_mesh_setter.set_body_part_colour(colour)
	mouth_mesh_setter.set_body_part_colour(colour)

func eat_consumable():
	pass

func get_drop_point() -> Vector3:
	return item_drop_point.global_position

func set_item_in_hand(slot_data):
	if slot_data != null:
		var item_name = slot_data.item_data.name
		var item = held_items[item_name].instantiate()
		hand_item_spawn.add_child(item)
		item.global_rotation.x = hand_item_spawn.global_rotation.x
		item.global_rotation.y = hand_item_spawn.global_rotation.y
	else:
		var held_item = hand_item_spawn.get_child(0)
		if held_item:
			held_item.queue_free()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Inventory"):
		toggle_inventory.emit()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "swing/swing":
		exit_state()

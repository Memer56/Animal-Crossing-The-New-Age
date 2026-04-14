extends CharacterBody3D

@export var textures : Array[Dictionary]
@export var eyes: MeshInstance3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var mesh: Node3D
@export var animation_player : AnimationPlayer
@export_enum("Tom", "Timmy", "Tommy", "Villager") var npc_type
@export var _name : String
##For giving npc's set locations to go
@export var predetermined_points : Marker3D
@onready var timer: Timer = $Timer

var speed = 80.0 #30.0
var direction = Vector3.ZERO
var acceleration = 10.0
var air_speed = 60.0 #22.0
var gravity = 80.0
var index : int = 0
var next_location : Vector3
var new_velocity : Vector3 = Vector3.ZERO
var nav_region : NavigationRegion3D
var map_rid : RID
var npc_has_reached_point : bool = false

func _ready() -> void:
	EventBus.send_nav_region.connect(recieve_nav_region)

func _physics_process(delta: float) -> void:
	if !npc_has_reached_point:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(new_velocity.x, new_velocity.z) - rotation.y, delta * 10)
	else:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, deg_to_rad(0.0), 0.25)
	apply_gravity(delta)

func _on_nav_update_timer_timeout() -> void:
	move_to_target()

func _on_timer_timeout() -> void:
	#switch_face()
	# For some reason writing the below logic like that stops it from chosing Vectos3(0,0,0) I think
	var will_npc_move = randi_range(1, 2)
	
	if npc_type == 1 or npc_type == 2: # Tommy or Timmy
		var point = await EventBus.player.global_position
		update_target_location.call_deferred(point)
	else:
		if will_npc_move == 1:
			var point = await get_random_point_on_nav_mesh()
			update_target_location.call_deferred(point)
		else:
			timer.start(10.0)

func get_random_point_on_nav_mesh() -> Vector3:
	await get_tree().process_frame
	var random_point : Vector3
	if nav_region:
		map_rid = nav_region.get_navigation_map()
	random_point = NavigationServer3D.map_get_random_point(map_rid, 1, true)
	return random_point

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta


func move_to_target():
	var current_location = global_position
	await get_tree().process_frame
	next_location = navigation_agent.get_next_path_position()
	new_velocity = (next_location - current_location).normalized() * speed
	#mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(new_velocity.x, new_velocity.z) - rotation.y, delta * 10)
	navigation_agent.set_velocity(new_velocity)

func update_target_location(target_location):
	# Call this to move npc
	var target_location_x = target_location.x
	var target_location_z = target_location.z
	if npc_type == 0:
		if !npc_has_reached_point:
			navigation_agent.target_position.x = predetermined_points.global_position.x
			navigation_agent.target_position.z = predetermined_points.global_position.z
			navigation_agent.target_position.normalized()
		else:
			speak_to_player()
	else:
		navigation_agent.target_position.x = target_location_x
		navigation_agent.target_position.z = target_location_z

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.25)
	if velocity:
		animation_player.play("npc_anim_library/Walk") # some anims are not from this lib!!!!
	elif velocity == Vector3.ZERO:
		animation_player.play("npc_anim_library/Idle")
	move_and_slide()


func switch_face():
	var material_override = StandardMaterial3D.new()
	material_override.roughness = 0.5
	material_override.normal_scale = 0.1
	if index == 0:
		index = 1
		material_override.albedo_texture = textures[1]["Sleep"][0]
		material_override.roughness_texture = textures[1]["Sleep"][1]
		material_override.normal_texture = textures[1]["Sleep"][2]
		material_override.normal_enabled = true
		eyes.set_surface_override_material(0, material_override)
	elif index == 1:
		index = 0
		material_override.albedo_texture = textures[0]["Happy"][0]
		material_override.roughness_texture = textures[0]["Happy"][1]
		material_override.normal_texture = textures[0]["Happy"][2]
		material_override.normal_enabled = true
		eyes.set_surface_override_material(0, material_override)

func speak_to_player():
	var npc_dialogue = NpcDialogue.new()
	var speech_bubble_info = npc_dialogue.get_correct_dialogue(_name, 0)
	EventBus.display_speech_bubble.emit(speech_bubble_info[0], speech_bubble_info[1], speech_bubble_info[2], speech_bubble_info[3])

func recieve_nav_region(_nav_region):
	nav_region = _nav_region


func _on_navigation_agent_3d_navigation_finished() -> void:
	if npc_type == 0:
		npc_has_reached_point = true
		velocity = Vector3.ZERO
		speak_to_player()
		#mesh.look_at(EventBus.player.global_position, Vector3.UP, true)
	else:
		timer.start()


func _on_navigation_agent_3d_target_reached() -> void:
	print("This signal was fired")
	if npc_type == 0:
		npc_has_reached_point = true
		velocity = Vector3.ZERO
		speak_to_player()
		lerp_angle(rotation.y, EventBus.player.rotation.y, 0.25)

extends StaticBody3D

@export var soft_mesh : MeshInstance3D
@export var door_window : MeshInstance3D
@export var animation_player : AnimationPlayer
@export var self_slot_data : SlotData
@export var building_windows : Array[MeshInstance3D]

func _ready() -> void:
	EventBus.toggle_service_buildings_lights.connect(toggle_lights)

func toggle_lights(variant : bool):
	for window in building_windows:
		var material : StandardMaterial3D = window.get_surface_override_material(0)
		material.emission_enabled = variant
	
	var soft_mesh_material : StandardMaterial3D = soft_mesh.get_surface_override_material(0)
	soft_mesh_material.emission_enabled = variant
	
	if door_window:
		var door_window_material : StandardMaterial3D = door_window.get_surface_override_material(0)
		door_window_material.emission_enabled = variant

func play_anim():
	animation_player.play("Toggle Door")

extends CharacterBody3D

@export var textures : Array[Dictionary]
@onready var body__m_eye: MeshInstance3D = $Rabbit_00/Armature/Skeleton3D/Body__mEye


var index : int = 0

func _on_timer_timeout() -> void:
	switch_face()

func switch_face():
	print("switching eyes")
	var material_override = StandardMaterial3D.new()
	material_override.roughness = 0.5
	material_override.normal_scale = 0.1
	if index == 0:
		index = 1
		material_override.albedo_texture = textures[1]["Sleep"][0]
		material_override.roughness_texture = textures[1]["Sleep"][1]
		material_override.normal_texture = textures[1]["Sleep"][2]
		material_override.normal_enabled = true
		body__m_eye.set_surface_override_material(0, material_override)
	elif index == 1:
		index = 0
		material_override.albedo_texture = textures[0]["Happy"][0]
		material_override.roughness_texture = textures[0]["Happy"][1]
		material_override.normal_texture = textures[0]["Happy"][2]
		material_override.normal_enabled = true
		body__m_eye.set_surface_override_material(0, material_override)

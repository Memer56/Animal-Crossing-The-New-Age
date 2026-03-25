extends StaticBody3D

signal send_damage(tool_slot_data : SlotData)

@export var tree_mesh : MeshInstance3D


func damage_object(slot_data : SlotData):
	send_damage.emit(slot_data)

func fade_tree():
	var tree : StandardMaterial3D = tree_mesh.get_surface_override_material(0).duplicate()
	var leaves : StandardMaterial3D = tree_mesh.get_surface_override_material(1).duplicate()
	
	tree_mesh.set_surface_override_material(0, tree)
	tree_mesh.set_surface_override_material(1, leaves)
	
	var tree_tween = get_tree().create_tween()
	tree.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tree_tween.tween_property(tree, "albedo_color:a", 0.0, 1.0)
	
	var leaves_tween = get_tree().create_tween()
	leaves.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	leaves_tween.tween_property(leaves, "albedo_color:a", 0.0, 1.0)

extends Node3D
# external because it's not naturally part of the node tree, nodes with this script are
# their own scenes
@export var node_to_set : MeshInstance3D

func set_body_part_colour(new_color : Color):
	print("New Colour : ", new_color)
	if node_to_set != null:
		var shader_material = node_to_set.get_surface_override_material(0)
		shader_material.set("shader_parameter/recolor", new_color)

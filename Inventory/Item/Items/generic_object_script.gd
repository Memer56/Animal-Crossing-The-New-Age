extends StaticBody3D

@export var self_slot_data : SlotData
@export var mesh_node : Node3D
@export var is_cursed_item : bool
@export var sphere : MeshInstance3D
@export var lighting_sphere : MeshInstance3D
@export var music : AudioStreamPlayer3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var player_hot_bar
var player_inventory
var output_item
var can_rotate : bool = true

var edge_mesh := BoxMesh.new()
var edge_mat := StandardMaterial3D.new()
var thickness := 0.3
var set_aabb_size : AABB

func _ready() -> void:
	player_hot_bar = EventBus.player.hotbar_inventory_data
	player_inventory = EventBus.player.inventory_data
	output_item = self_slot_data
	set_object_aabb()
	if is_cursed_item:
		begin_havoc()

func add_self_to_player_inventory():
	# Does this account for full inventory????
	var is_there_an_empty_slot_hotbar = player_hot_bar.are_there_slots_available()
	var is_there_an_empty_slot_inventory = player_inventory.are_there_slots_available()

	var is_in_hot_bar : SlotData = player_hot_bar.is_item_in_inventory_return_slot_data(output_item.item_data.name)
	#var is_in_inventory : SlotData = player_inventory.is_item_in_inventory_return_slot_data(output_item.item_data.name)
	#player_hot_bar.add_to_inventory_with_quantity(output_item, output_item.quantity)
	#player_inventory.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if is_in_hot_bar and is_in_hot_bar.quantity < 64 and is_there_an_empty_slot_hotbar:
		player_hot_bar.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if is_in_hot_bar and !is_there_an_empty_slot_hotbar:
		if return_if_total_less_than_max_stack_size(is_in_hot_bar):
			player_hot_bar.add_to_inventory_with_quantity(output_item, output_item.quantity)
		else:
			player_inventory.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if !is_in_hot_bar and is_there_an_empty_slot_hotbar:
		player_hot_bar.add_to_inventory_with_quantity(output_item, output_item.quantity)
	if !is_in_hot_bar and !is_there_an_empty_slot_hotbar:
		player_inventory.add_to_inventory_with_quantity(output_item, output_item.quantity)
	
	collision_shape_3d.shape = null # Prevents nav rebake from using objects collision shape
	EventBus.bake_nav_mesh.emit()
	queue_free()

func return_if_total_less_than_max_stack_size(slot_data : SlotData) -> bool:
	var total = slot_data.quantity + output_item.quantity
	if total <= 64:
		return true
	else:
		return false


func rotate_self(rotation_direction : float):
	if can_rotate:
		can_rotate = false
		var target_radians = rotation.y + deg_to_rad(rotation_direction)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "rotation:y", target_radians, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await get_tree().create_timer(1).timeout
		can_rotate = true

func begin_havoc():
	await get_tree().create_timer(2).timeout
	var tween = get_tree().create_tween()
	var mat = sphere.mesh.surface_get_material(0).duplicate()
	mat.emission_enabled = true
	sphere.set_surface_override_material(0, mat)
	tween.tween_property(mat, "emission_energy_multiplier", 3.0, 0.25)
	await get_tree().create_timer(0.6).timeout
	lighting_sphere.show()
	music.play()


func set_object_aabb():
	var merged_aabb : AABB
	for child in mesh_node.get_children():
		var aabb = child.get_aabb()
		merged_aabb = merged_aabb.merge(aabb)
	set_aabb_size = merged_aabb
	set_aabb_size = expanded_aabb(set_aabb_size, 2.0)

func expanded_aabb(aabb: AABB, margin: float) -> AABB:
	var new_position = aabb.position - Vector3.ONE * margin
	var new_size = aabb.size + Vector3.ONE * margin * 2.0
	return AABB(new_position, new_size)


func get_aabb_bounding() -> AABB:
	draw_aabb(set_aabb_size)
	return set_aabb_size

func draw_aabb(aabb: AABB, color: Color = Color("da41ffff")):
	# Litterally have no clue what's going on here
	
	edge_mesh.size = Vector3.ONE

	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_mat.albedo_color = color
	edge_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	
	# Clear old edges
	for e in BuildManager.edge_instances:
		e.queue_free()
	BuildManager.edge_instances.clear()

	var p = aabb.position
	var s = aabb.size

	var corners = [
		p,
		p + Vector3(s.x, 0, 0),
		p + Vector3(s.x, s.y, 0),
		p + Vector3(0, s.y, 0),
		p + Vector3(0, 0, s.z),
		p + Vector3(s.x, 0, s.z),
		p + Vector3(s.x, s.y, s.z),
		p + Vector3(0, s.y, s.z),
	]

	var edges = [
		[0,1],[1,2],[2,3],[3,0],
		[4,5],[5,6],[6,7],[7,4],
		[0,4],[1,5],[2,6],[3,7]
	]

	for e in edges:
		_create_edge(corners[e[0]], corners[e[1]])

func _create_edge(a: Vector3, b: Vector3):
	var edge = MeshInstance3D.new()
	edge.mesh = edge_mesh
	edge.material_override = edge_mat
	get_tree().root.get_node("/root/EdgeMeshNode").add_child(edge)
	get_tree().root.get_node("/root/EdgeMeshNode").global_position = global_position
	BuildManager.edge_instances.append(edge)

	var dir = (b - a)
	var length = dir.length()
	dir = dir.normalized()

	# Build a basis where Z axis points along the edge
	var basis = Basis()
	basis.z = dir
	basis.x = dir.cross(Vector3.UP).normalized()
	basis.y = basis.z.cross(basis.x).normalized()

	# If edge is vertical, cross product breaks — fix it
	if basis.x.length() < 0.001:
		basis.x = dir.cross(Vector3.FORWARD).normalized()
		basis.y = basis.z.cross(basis.x).normalized()

	edge.transform = Transform3D(basis, (a + b) * 0.5)

	# Now scale the box: thin on X/Y, long on Z
	edge.scale = Vector3(thickness, thickness, length)

func clear_aabb_visual():
	for e in BuildManager.edge_instances:
		e.queue_free()
	BuildManager.edge_instances.clear()

#func draw_aabb(aabb: AABB, color: Color = Color.RED):
	## I don't have a cl
	#var im := ImmediateMesh.new()
	#var mesh = MeshInstance3D.new()
	#var mat = StandardMaterial3D.new()
	#
	#mesh.mesh = im
	#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#mat.albedo_color = Color(1, 0, 0, 0.35)
	#
	#im.clear_surfaces()
	#im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
#
	#var p = aabb.position
	#var s = aabb.size
#
	## 8 corners of the box
	#var corners = [
		#p,
		#p + Vector3(s.x, 0, 0),
		#p + Vector3(s.x, s.y, 0),
		#p + Vector3(0, s.y, 0),
#
		#p + Vector3(0, 0, s.z),
		#p + Vector3(s.x, 0, s.z),
		#p + Vector3(s.x, s.y, s.z),
		#p + Vector3(0, s.y, s.z),
	#]
#
	## edges of the box (pairs of indices)
	#var edges = [
		#0,1, 1,2, 2,3, 3,0,   # bottom
		#4,5, 5,6, 6,7, 7,4,   # top
		#0,4, 1,5, 2,6, 3,7    # sides
	#]
#
	#for i in range(0, edges.size(), 2):
		#im.surface_add_vertex(corners[edges[i]])
		#im.surface_add_vertex(corners[edges[i+1]])
	#
	#add_child(mesh)
	#im.surface_end()

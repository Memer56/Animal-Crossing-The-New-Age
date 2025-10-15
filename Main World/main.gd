extends Node3D
# Set Roughness value to 0.5 and Normal to 0.1
const PICK_UP = preload("uid://c8p87t4ex6hyc")

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/InventoryInterface/HotBarInventory

func _ready() -> void:
	EventBus.player.toggle_inventory.connect(toggle_inventory_interface)
	hot_bar_inventory.send_held_slot_data.connect(EventBus.player.set_item_in_hand)
	inventory_interface.set_player_inventory_data(EventBus.player.inventory_data)
	inventory_interface.set_player_hot_bar_inventory(EventBus.player.hot_bar_inventory_data)
	connect_toggle_external_inventory_signal()
	#begin_river_generation()

func connect_toggle_external_inventory_signal():
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.player_inventory.visible = not inventory_interface.player_inventory.visible
	
	if inventory_interface.player_inventory.visible:
		EventBus.game_paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#get_tree().paused = true
		inventory_interface.player_inventory.visible = true
		#inventory_interface.equip_inventory.visible = true
	else:
#		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		EventBus.game_paused = false
		inventory_interface.player_inventory.visible = false
		#inventory_interface.equip_inventory.visible = false
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()



func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PICK_UP.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = EventBus.player.get_drop_point()
	add_child(pick_up)


#func begin_river_generation():
	#var new_river = MeshInstance3D.new()
	#var new_shader_material = ShaderMaterial.new()
	#new_shader_material.shader = preload("res://Shaders/River.gdshader")
	#path_3d.add_child(new_river)
	#get_river_nodes()
	#new_river.mesh = generate_river_mesh(path_3d.curve, 100.0, path_3d.curve.point_count)
	#new_river.global_position.y = 0
	#new_river.material_override = new_shader_material
#
#func get_river_nodes():
	#for i in river_nodes.get_children():
		#path_3d.curve.add_point(i.global_position)
#
#func generate_river_mesh(curve: Curve3D, width: float, segments: int) -> ArrayMesh:
	#var st = SurfaceTool.new()
	#st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#
	#var baked_length = curve.get_baked_length()
	#
	#var prev_across = Vector3(1,0,0) # initial across vector
	#
	#for i in range(segments + 1):
		#var t = float(i)/segments
		#t = clamp(t, 0.0, 1.0)
		#
		#var center = curve.sample_baked(t * baked_length)
		#if i == segments:
			#center = curve.get_point_position(curve.get_point_count()-1)
		#
		#var next_t = clamp((i + 1)/segments, 0.0, 1.0)
		#var next = curve.sample_baked(next_t * baked_length)
		#
		#var tangent = (next - center).normalized()
		#
		## compute across vector perpendicular to tangent, preserving continuity
		#var across = (prev_across - tangent * prev_across.dot(tangent)).normalized()
		#prev_across = across # store for next segment
		#
		#var left = center - across * width * 0.5
		#var right = center + across * width * 0.5
		#
		#var v = t
		#st.set_uv(Vector2(0, v))
		#st.add_vertex(left)
		#st.set_uv(Vector2(1, v))
		#st.add_vertex(right)
		#
		#if i > 0:
			#var idx = i*2
			#st.add_index(idx-2)
			#st.add_index(idx)
			#st.add_index(idx-1)
			#
			#st.add_index(idx)
			#st.add_index(idx+1)
			#st.add_index(idx-1)
	#
	#st.generate_normals()
	#return st.commit()



#func generate_uvs():
	#if not csg_polygon_3d or not csg_baked_mesh_instance_3d:
		#push_error("Assign river_path and river_mesh_instance in the inspector")
		#return
	#
	#var curve = path_3d.curve
	#var mesh: ArrayMesh = csg_baked_mesh_instance_3d.mesh
	#var mdt = MeshDataTool.new()
	#mdt.create_from_surface(mesh, 0)
	#
	## Precompute curve total length for normalization
	#var total_length = curve.get_baked_length()
	#
	#for i in range(mdt.get_vertex_count()):
		#var vertex = mdt.get_vertex(i)
		#
		## Find closest point on the river curve
		#var closest_offset = curve.get_closest_offset(vertex)
		#var along_distance = closest_offset / total_length  # normalized 0–1
		#
		## We’ll assume “across” the river runs roughly perpendicular to the curve direction
		## Use world XZ position difference for a basic approximation
		#var curve_point = curve.sample_baked(closest_offset)
		#var across_dir = (vertex - curve_point).normalized()
		#var across_value = across_dir.dot(Vector3.RIGHT) * 0.5 + 0.5  # range 0–1
		#
		#mdt.set_vertex_uv(i, Vector2(across_value, along_distance))
	#
	#mdt.commit_to_surface(mesh)

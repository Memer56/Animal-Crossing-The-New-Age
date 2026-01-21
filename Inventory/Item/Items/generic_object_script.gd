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

func _ready() -> void:
	player_hot_bar = EventBus.player.hotbar_inventory_data
	player_inventory = EventBus.player.inventory_data
	output_item = self_slot_data
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

func highlight_object():
	if mesh_node:
		for mesh in mesh_node.get_children():
			var mat = mesh.mesh.surface_get_material(0)
			mat.stencil_mode = 1

func remove_object_highlight():
	if mesh_node:
		for mesh in mesh_node.get_children():
			var mat = mesh.mesh.surface_get_material(0)
			mat.stencil_mode = 0

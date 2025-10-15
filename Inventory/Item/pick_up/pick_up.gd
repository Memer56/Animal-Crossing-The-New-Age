extends StaticBody3D

@export var slot_data : SlotData
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var animation_player = $AnimationPlayer

func _ready():
	mesh_instance_3d.mesh = slot_data.item_data.mesh
	animation_player.play("anim")


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.hot_bar_inventory_data.pick_up_slot_data(slot_data):
		queue_free()
	elif body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()


func _on_timer_timeout():
	queue_free()

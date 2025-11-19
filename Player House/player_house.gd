extends Node3D

var nav_mesh_area_node : Area3D

func _ready() -> void:
	nav_mesh_area_node =  get_tree().get_nodes_in_group("ModularToggleNavMeshBoolArea")[0]
	nav_mesh_area_node.body_entered.connect(_on_allow_player_near_area_body_entered)
	nav_mesh_area_node.body_exited.connect(_on_allow_player_near_area_body_exited)


func _on_allow_player_near_area_body_entered(body: Node3D) -> void:
	if body.get_collision_layer() == 1:
		EventBus.player_can_leave_nav_mesh = true


func _on_allow_player_near_area_body_exited(body: Node3D) -> void:
	if body.get_collision_layer() == 1:
		EventBus.player_can_leave_nav_mesh = false

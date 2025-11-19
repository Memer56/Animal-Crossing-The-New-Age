extends StaticBody3D

@export var soft_mesh : MeshInstance3D
@export var animation_player : AnimationPlayer

func play_anim():
	animation_player.play("Toggle Door")


func _on_allow_player_near_area_body_entered(body: Node3D) -> void:
	if body.get_collision_layer() == 1:
		EventBus.player_can_leave_nav_mesh = true


func _on_allow_player_near_area_body_exited(body: Node3D) -> void:
	if body.get_collision_layer() == 1:
		EventBus.player_can_leave_nav_mesh = false

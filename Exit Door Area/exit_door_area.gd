extends Area3D

var allow_player_to_exit : bool = false
var set_speed_to_zero : bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.get_collision_layer() == 1 and allow_player_to_exit:
		body.doorway_events_can_trigger = true
		body.should_force_rotation_for_entry = false
		body.state = body.ENTER_DOOR
		body.toggle_collisions(2, false)
		EventBus.trigger_building_exit_event = true
		EventBus.save_game_data.emit()
		EventBus.item_was_bought_during_visit = false


func _on_body_exited(_body: Node3D) -> void:
	allow_player_to_exit = true


func _on_timer_timeout() -> void:
	allow_player_to_exit = true

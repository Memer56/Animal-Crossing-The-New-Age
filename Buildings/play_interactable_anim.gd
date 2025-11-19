extends StaticBody3D

signal play
@export var room : String
@export var player_spawn_point : Marker3D

func play_anim():
	EventBus.room_to_spawn = room
	play.emit()

func return_spawn_point() -> Vector3:
	return player_spawn_point.global_position

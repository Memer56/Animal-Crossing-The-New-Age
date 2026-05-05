extends StaticBody3D

signal play
@export var room : String
@export var player_spawn_point : Marker3D

func play_anim():
	if !EventBus.service_buildings_closed:
		EventBus.room_to_spawn = room
		play.emit()
	else:
		EventBus.display_speech_bubble.emit(["Looks like they're closed."], "Info", [], null)

func return_spawn_point() -> Vector3:
	return player_spawn_point.global_position

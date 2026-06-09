extends Node3D

@onready var player_spawn_point: Marker3D = $PlayerSpawnPoint
@onready var tom_spawn_point: Marker3D = $TomSpawnPoint
@onready var player_secondary_point: Marker3D = $PlayerSecondaryPoint

func return_tom_spawn_point() -> Vector3:
	return tom_spawn_point.global_position

func return_player_spawn_point() -> Vector3:
	return player_spawn_point.global_position

func return_player_secondary_point() -> Vector3:
	return player_secondary_point.global_position

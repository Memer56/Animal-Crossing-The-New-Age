extends StaticBody3D

@export var room : String
@export var player_spawn_point : Marker3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	player_spawn_point = get_tree().get_nodes_in_group("ModularPlayerSpawnPoint")[0]

func play_anim():
	EventBus.room_to_spawn = room
	animation_player.play("Toggle Door")

func return_spawn_point() -> Vector3:
	return player_spawn_point.global_position

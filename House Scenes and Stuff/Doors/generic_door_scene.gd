extends StaticBody3D

## Rounded corners doors
const DOOR_CARVING_AR = preload("uid://d3alfcbp1th8i")
const DOOR_CHINESE_AR = preload("uid://bs8iinvwrmh1h")
const DOOR_IRONPARTS_AR = preload("uid://bijk0vy1xvfyo")
const DOOR_JAPANESE_AR = preload("uid://bp4bm4rjmcmli")
const DOOR_VERTICAL_WINDOW_AR = preload("uid://d17m5oijjxhmx")

## Non-rounded corners doors
const DOOR_CARVING_AS = preload("uid://fj5lx5dgtmtg")
const DOOR_CHINESE_AS = preload("uid://cej06coi5llkl")
const DOOR_IRONPARTS_AS = preload("uid://p0qw52ve1vgu")
const DOOR_JAPANESE_AS = preload("uid://diunrei438qnh")
const DOOR_VERTICAL_WINDOW_AS = preload("uid://vem8vvk2va54")

@export var room : String
@export var door_corner_type : String
@onready var door: Node3D = $Door

var door_offset : Vector3 = Vector3(7.19, 0.0, -1.607)
var door_offset_x_axis : Vector3 = Vector3(-6.006, 0.0, 0.0)
var door_types : Array = ["carving", "chinese", "ironparts", "japanese", "vertical_window"]

func _ready() -> void:
	spawn_door()

func spawn_door():
	var new_door = get_correct_door_model()
	door.add_child(new_door)
	new_door.position = door_offset_x_axis

func get_correct_door_model():
	var new_door
	match door_corner_type:
		"ar":
			new_door = give_door_type_rounded()
		"as":
			new_door = give_door_type_straight()
	return new_door


func give_door_type_rounded():
	var chosen_door = door_types.pick_random()
	var new_door
	match chosen_door:
		"carving":
			new_door = DOOR_CARVING_AR.instantiate()
		"chinese":
			new_door = DOOR_CHINESE_AR.instantiate()
		"ironparts":
			new_door = DOOR_IRONPARTS_AR.instantiate()
		"japanese":
			new_door = DOOR_JAPANESE_AR.instantiate()
		"vertical_window":
			new_door = DOOR_VERTICAL_WINDOW_AR.instantiate()
	
	return new_door

func give_door_type_straight():
	var chosen_door = door_types.pick_random()
	var new_door
	match chosen_door:
		"carving":
			new_door = DOOR_CARVING_AS.instantiate()
		"chinese":
			new_door = DOOR_CHINESE_AS.instantiate()
		"ironparts":
			new_door = DOOR_IRONPARTS_AS.instantiate()
		"japanese":
			new_door = DOOR_JAPANESE_AS.instantiate()
		"vertical_window":
			new_door = DOOR_VERTICAL_WINDOW_AS.instantiate()
	
	return new_door

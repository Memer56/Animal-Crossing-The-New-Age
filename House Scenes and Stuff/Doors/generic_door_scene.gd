extends StaticBody3D

signal send_door_info(corner_type : String, door_type : String)

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

const DOOR_WINDOW_MATERIAL = preload("uid://cdlmfn1lapjf4")

@export var room : String
@export var door_corner_type : String
@export var saved_door_type : String
@onready var door: Node3D = $Door

var door_offset : Vector3 = Vector3(7.19, 0.0, -1.607)
var door_offset_x_axis : Vector3 = Vector3(-6.006, 0.0, 0.0)
var door_types : Array = ["carving", "chinese", "ironparts", "japanese", "vertical_window"]
var door_glass_pane_colour : Color = Color(0.122, 0.122, 0.122, 1.0)
var chosen_door_type : String

func _ready() -> void:
	spawn_door()

func spawn_door():
	var new_door = get_correct_door_model()
	door.add_child(new_door)
	new_door.position = door_offset_x_axis
	darken_door_window_pane()
	send_door_info.emit(door_corner_type, chosen_door_type)

func get_correct_door_model():
	var new_door
	match door_corner_type:
		"ar":
			new_door = give_door_type_rounded()
		"as":
			new_door = give_door_type_straight()
	return new_door


func give_door_type_rounded():
	var chosen_door
	var new_door
	
	if EventBus.game_is_new_save:
		chosen_door = door_types.pick_random()
	else:
		chosen_door = saved_door_type
	
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
	
	chosen_door_type = chosen_door
	return new_door

func give_door_type_straight():
	var chosen_door
	var new_door
	
	if EventBus.game_is_new_save:
		chosen_door = door_types.pick_random()
	else:
		chosen_door = saved_door_type
	
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
	
	chosen_door_type = chosen_door
	return new_door

func darken_door_window_pane():
	for child in door.get_children():
		for lower_child in child.get_children():
			if lower_child.name.contains("mWindow"):
				var new_material : StandardMaterial3D = DOOR_WINDOW_MATERIAL.duplicate()
				lower_child.set_material_override(new_material)

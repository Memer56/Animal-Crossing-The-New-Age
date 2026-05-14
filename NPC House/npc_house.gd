extends Node3D

## Walls
const WALL_NA_BRICK_A = preload("uid://qc20ojnq3s0h")
const WALL_NB_LOG_A = preload("uid://dukpsskk2jbel")
const WALL_NB_STONE_A = preload("uid://cq736ae7e55lx")
const WALL_ND_SOIL_E = preload("uid://va3himtrgagd")

## Roofs
const ROOF_NA_TILE_A = preload("uid://dkbrn8e14u0ts")
const ROOF_NB_WOODPANEL_G = preload("uid://vvmfn2lwwfp8")
const ROOF_ND_WOOD_I = preload("uid://cywsuew5ak3xc")

## Door
const GENERIC_DOOR_SCENE = preload("uid://bhso4wcldbmwn")

@onready var house_walls: Node3D = $HouseWalls
@onready var house_roof: Node3D = $HouseRoof
@onready var house_door: Node3D = $HouseDoor
## index 0 = Transform3D / index 1 = wall type / index 2 = variant of wall type / index 3 = chosen roof / index 4 = roof variant
## index 5 = chosen door / index 6 = door corner type / index 7 = assigned villager
@export var house_data : Array

var wall_types : Array = ["brick", "log", "stone", "soil"]
var set_wall
var set_roof
var set_door
var set_corner_type

######## FINISH ADDING SUPPORT FOR SAVING NPC HOUSES #######################

func _ready() -> void:
	if EventBus.game_is_new_save:
		house_data.append(self.global_transform)
	construct_house()

func construct_house():
	var chosen_walls_and_roofs : Array = select_wall()
	var walls = chosen_walls_and_roofs[0]
	var roof = chosen_walls_and_roofs[1]

	house_walls.add_child(walls)
	house_roof.add_child(roof)
	
	if EventBus.game_is_new_save:
		var data : Array = [global_transform, set_wall, "wall variant", set_roof, "roof variant", set_door, set_corner_type, "villager name"]
		house_data = data

func select_wall() -> Array:
	var chosen_wall
	var wall_tag : String
	var wall_corners : String
	var final_walls_and_roof : Array
	var new_wall
	
	if EventBus.game_is_new_save:
		new_wall = wall_types.pick_random()
	else:
		new_wall = house_data[1]
	
	match new_wall:
		"brick":
			chosen_wall = WALL_NA_BRICK_A.instantiate()
			wall_tag = "na"
			wall_corners = "as"
		"log":
			chosen_wall = WALL_NB_LOG_A.instantiate()
			wall_tag = "nb"
			wall_corners = "ar"
		"stone":
			chosen_wall = WALL_NB_STONE_A.instantiate()
			wall_tag = "nb"
			wall_corners = "ar"
		"soil":
			chosen_wall = WALL_ND_SOIL_E.instantiate()
			wall_tag = "nd"
			wall_corners = "ar"
	
	final_walls_and_roof.append(chosen_wall)
	if EventBus.game_is_new_save:
		final_walls_and_roof.append(select_roof(wall_tag))
		set_wall = new_wall
		spawn_door(wall_corners)
	else:
		final_walls_and_roof.append(select_roof(house_data[3]))
		spawn_door(house_data[6])
	
	return final_walls_and_roof

func select_roof(wall_tag : String):
	var chosen_roof
	match wall_tag:
		"na":
			chosen_roof = ROOF_NA_TILE_A.instantiate()
		"nb":
			chosen_roof = ROOF_NB_WOODPANEL_G.instantiate()
		"nd":
			chosen_roof = ROOF_ND_WOOD_I.instantiate()
	
	set_roof = wall_tag
	return chosen_roof

func spawn_door(wall_corner_type : String):
	var new_door = GENERIC_DOOR_SCENE.instantiate()
	new_door.door_corner_type = wall_corner_type
	new_door.send_door_info.connect(_on_send_door_info)
	if !EventBus.game_is_new_save:
		new_door.saved_door_type = house_data[5]
	
	house_door.add_child(new_door)

func _on_send_door_info(corner_type : String, door_type : String):
	set_corner_type = corner_type
	set_door = door_type

extends Node3D

## Walls
const WALL_NA_BRICK_A = preload("uid://qc20ojnq3s0h")
const WALL_NB_LOG_A = preload("uid://dukpsskk2jbel")
const WALL_NB_STONE_A = preload("uid://cq736ae7e55lx")
const WALL_ND_SOIL_E = preload("uid://va3himtrgagd")

## Roofs
const ROOF_NA_TILE_A = preload("uid://cc1d2hi6l7y5w")
const ROOF_NB_WOODPANEL_G = preload("uid://6wxknnndqykr")
const ROOF_ND_WOOD_I = preload("uid://o5fklupgjgro")

@onready var house_walls: Node3D = $HouseWalls
@onready var house_roof: Node3D = $HouseRoof
@onready var house_door: Node3D = $HouseDoor

var wall_types : Array = ["brick", "log", "stone", "soil"]

func _ready() -> void:
	construct_house()

func construct_house():
	var chosen_walls_and_roofs : Array = select_wall()
	var walls = chosen_walls_and_roofs[0]
	var roof = chosen_walls_and_roofs[1]

	house_walls.add_child(walls)
	house_roof.add_child(roof)

func select_wall() -> Array:
	var new_wall = wall_types.pick_random()
	var chosen_wall
	var wall_tag : String
	var final_walls_and_roof : Array
	
	match new_wall:
		"brick":
			chosen_wall = WALL_NA_BRICK_A.instantiate()
			wall_tag = "na"
		"log":
			chosen_wall = WALL_NB_LOG_A.instantiate()
			wall_tag = "nb"
		"stone":
			chosen_wall = WALL_NB_STONE_A.instantiate()
			wall_tag = "nb"
		"soil":
			chosen_wall = WALL_ND_SOIL_E.instantiate()
			wall_tag = "nd"
	final_walls_and_roof.append(chosen_wall)
	final_walls_and_roof.append(select_roof(wall_tag))
	
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
	return chosen_roof

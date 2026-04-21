extends Node3D

@onready var house_exit: Node3D = $house_exit

#### Floors ####
@onready var _6x_6: Node3D = $"6x6"
@onready var _8x_8: Node3D = $"8x8"
@onready var _10x_10: Node3D = $"10x10"

#### Walls ####
@onready var _6x_6_wall: Node3D = $"6x6Wall"
@onready var _8x_8_wall: Node3D = $"8x8Wall"
@onready var _10x_10_wall: Node3D = $"10x10Wall"

#### Wall Collisions ####
@onready var _6x_6_wall_collision: StaticBody3D = $"6x6Wall/6x6WallCollision"
@onready var _8x_8_wall_collision: StaticBody3D = $"8x8Wall/8x8WallCollision"

var defaut_house_exit_z_position : float = 30.0

func _ready() -> void:
	show_correct_interior_size()

func show_correct_interior_size():
	var wall_collision_to_hide_1 : StaticBody3D
	var wall_collisio_to_hide_2 : StaticBody3D
	
	match EventBus.house_level:
		1:
			_6x_6.show()
			_8x_8.hide()
			_10x_10.hide()
			
			_6x_6_wall.show()
			_8x_8_wall.hide()
			_10x_10_wall.hide()
		2:
			_6x_6.hide()
			_8x_8.show()
			_10x_10.hide()
			
			_6x_6_wall.hide()
			_8x_8_wall.show()
			_10x_10_wall.hide()
			offset_house_exit_z_axis(40.0)
			wall_collision_to_hide_1 = _6x_6_wall_collision
			# This isn't needed twice but the function requires two arguments
			wall_collisio_to_hide_2 = _6x_6_wall_collision
		3:
			_6x_6.hide()
			_8x_8.hide()
			_10x_10.show()
			
			_6x_6_wall.hide()
			_8x_8_wall.hide()
			_10x_10_wall.show()
			offset_house_exit_z_axis(50.0)
			wall_collision_to_hide_1 = _8x_8_wall_collision
			wall_collisio_to_hide_2 = _6x_6_wall_collision
		4:
			_6x_6.hide()
			_8x_8.hide()
			_10x_10.show()
			
			_6x_6_wall.hide()
			_8x_8_wall.hide()
			_10x_10_wall.show()
			offset_house_exit_z_axis(50.0)
			wall_collision_to_hide_1 = _8x_8_wall_collision
			wall_collisio_to_hide_2 = _6x_6_wall_collision
	
	if wall_collision_to_hide_1:
		disable_wall_collision(wall_collision_to_hide_1, wall_collisio_to_hide_2)


func offset_house_exit_z_axis(new_z_point : float):
	house_exit.global_position.z = new_z_point

func disable_wall_collision(wall_collision_1 : StaticBody3D, wall_collision_2 : StaticBody3D):
	wall_collision_1.set_collision_layer_value(2, false)
	wall_collision_1.set_collision_mask_value(1, false)
	
	wall_collision_2.set_collision_layer_value(2, false)
	wall_collision_2.set_collision_mask_value(1, false)

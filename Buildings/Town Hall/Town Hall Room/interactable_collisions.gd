extends StaticBody3D

@export var tom : CharacterBody3D

func trigger_dialogue():
	tom.update_target_location(Vector3.ZERO)

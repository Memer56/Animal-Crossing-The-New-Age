extends Resource
class_name ItemData

@export var name : String = ""
@export_multiline var description : String = ""
@export var stackable : bool = false
@export var texture : AtlasTexture
@export var mesh : ArrayMesh
@export var price : int
@export var sell_value : int
@export var mining_value : int
@export var defence_value : int
@export var ID : int

func use(target) -> void:
	pass

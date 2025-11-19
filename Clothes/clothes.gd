extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree

var anim_speed : float = 1.0

func _ready() -> void:
	EventBus.update_clothes_anim.connect(update_clothes_anim)

func _physics_process(delta: float) -> void:
	animation_tree.advance(delta * anim_speed)

func update_clothes_anim(anim : String, _anim_speed : float):
	anim_speed = _anim_speed
	var anim_state = animation_tree.get("parameters/playback")
	anim_state.travel(anim)

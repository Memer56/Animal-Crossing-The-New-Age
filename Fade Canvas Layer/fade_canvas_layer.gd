extends CanvasLayer

@onready var fade_panel: Panel = $Control/FadePanel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hide_ugly_stuff_panel: Panel = $Control/HideUglyStuffPanel


func _ready() -> void:
	EventBus.toggle_fade.connect(trigger_scene_change_fade)
	if EventBus.is_in_overworld:
		if hide_ugly_stuff_panel.visible == false:
			#print("Displaying ulgy panel")
			hide_ugly_stuff_panel.show()

func trigger_scene_change_fade(fade_out : bool):
	#var fade_panel_material = fade_panel.material
	var delay : float
	var anim : String
	
	if fade_out:
		#fade_panel_material.set_shader_parameter("shrink", true)
		delay = 0.0
		anim = "fade_out"
	else:
		#fade_panel_material.set_shader_parameter("shrink", false)
		delay = 1.0
		anim = "fade_in"

	await get_tree().create_timer(delay).timeout
	animation_player.play(anim)

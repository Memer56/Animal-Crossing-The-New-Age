extends CanvasLayer

@onready var fade_panel: Panel = $Control/FadePanel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hide_ugly_stuff_panel: Panel = $Control/HideUglyStuffPanel
@onready var load_icon_anim: AnimationPlayer = $LoadIconAnim
@onready var loading_icon: TextureRect = $Control/LoadingIcon


func _ready() -> void:
	EventBus.toggle_fade.connect(trigger_scene_change_fade)
	if EventBus.is_in_overworld:
		if hide_ugly_stuff_panel.visible == false:
			#print("Displaying ulgy panel")
			hide_ugly_stuff_panel.show()
		load_icon_anim.play("Fade")

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


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	load_icon_anim.stop()
	loading_icon.hide()


func _on_load_icon_anim_animation_started(anim_name: StringName) -> void:
	print("Playing anim : ", anim_name)

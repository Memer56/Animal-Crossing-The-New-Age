extends Control

@onready var count_label: RichTextLabel = $HBoxContainer/CountLabel
@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var h_box_container: HBoxContainer = $HBoxContainer


func load_data(_known_count : int, _required_count : int, texture : Texture2D, can_craft_item):
	#update tooltip
	var text_colour : String
	if can_craft_item:
		text_colour = "[color=lightgreen]"
	else:
		text_colour = "[color=indianred]"
	
	count_label.clear()
	count_label.append_text(text_colour + str(_known_count) + "[/color]" + "/" + str(_required_count))
	texture_rect.texture = texture

func set_ui_scale(_size : Vector2):
	await get_tree().create_timer(1).timeout
	set_size(_size)
	print("Changed size: "," Given Size: ", _size, " Size: ", size)

func get_texture() -> Texture:
	return texture_rect.texture

extends Control

@export var is_one_paragraph : bool = false
@onready var rich_text_label: RichTextLabel = $TextureRect/RichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $TextureRect/NameTag/Label
@onready var arrow_anim: AnimationPlayer = $ArrowAnim

var text_to_say : Array
var text_index : int = 0
var num_of_paragraphs : int

func _ready() -> void:
	arrow_anim.play("arrow")
	EventBus.display_speech_bubble.connect(display_text)

func display_text(new_text_array : Array, npc_name : String):
	num_of_paragraphs = new_text_array.size()
	text_to_say = new_text_array
	text_index = 0
	if num_of_paragraphs > 1:
		is_one_paragraph = false
	else:
		is_one_paragraph = true
	clear_previous_text()
	animation_player.play("anim")
	rich_text_label.append_text(text_to_say[0])
	label.text = npc_name

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_one_paragraph:
				animation_player.play_backwards("anim")
				clear_previous_text()
			elif !is_one_paragraph and text_index < (num_of_paragraphs - 1):
				text_index += 1
				clear_previous_text()
				rich_text_label.append_text(text_to_say[text_index])
			else:
				animation_player.play_backwards("anim")
				clear_previous_text()

func clear_previous_text():
	rich_text_label.text = ""

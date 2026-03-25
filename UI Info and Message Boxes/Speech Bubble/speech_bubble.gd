extends Control

@export var is_one_paragraph : bool = false
@onready var rich_text_label: RichTextLabel = $TextureRect/RichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $TextureRect/NameTag/Label
@onready var arrow_anim: AnimationPlayer = $ArrowAnim
@onready var answer_panel: Panel = $TextureRect/AnswerPanel

var text_to_say : Array
var text_index : int = 0
var num_of_paragraphs : int
## this variable determines if and where a question was asked, it may contain slot data info if an item is being passed
var question_at_index : Array
var question_result : bool = false

func _ready() -> void:
	arrow_anim.play("arrow")
	EventBus.display_speech_bubble.connect(display_text)

func display_text(new_text_array : Array, npc_name : String, _question_at_index : Array):
	num_of_paragraphs = new_text_array.size()
	text_to_say = new_text_array
	text_index = 0
	question_at_index = _question_at_index
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
		if answer_panel.visible == false:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if question_at_index and text_index == question_at_index[1]:
					toggle_answer_panel()
				
				else:
					progress_speech_bubble()

func progress_speech_bubble():
	 # Setting text_index to 3 ensures the below condition is false to allow the speech bubble to close
	if text_index < (num_of_paragraphs - 1):
		text_index += 1
		clear_previous_text()
		if question_at_index[1] != null:
			if question_result == true:
				if !EventBus.savings_balance >= question_at_index[2].item_value:
					clear_previous_text()
					rich_text_label.append_text("Sorry, it looks like you can't afford this item.")
					text_index = 3
					return
				rich_text_label.append_text(text_to_say[1])
				EventBus.player.hotbar_inventory_data.add_to_inventory(question_at_index[2].item_slot_data)
				question_at_index[2].set_display_to_sold()
				EventBus.savings_balance -= question_at_index[2].item_value
				EventBus.item_was_bought_during_visit = true
				text_index = 2
			else:
				rich_text_label.append_text(text_to_say[2])
				text_index = 3
		else:
			rich_text_label.append_text(text_to_say[text_index])
	
	else:
		hide_speech_bubble()

func hide_speech_bubble():
	animation_player.play_backwards("anim")
	clear_previous_text()

func clear_previous_text():
	rich_text_label.text = ""

func toggle_answer_panel():
	if answer_panel.visible:
		answer_panel.hide()
	else:
		answer_panel.show()

func _on_ill_take_it_pressed() -> void:
	question_result = true
	toggle_answer_panel()
	progress_speech_bubble()


func _on_maybe_later_pressed() -> void:
	question_result = false
	toggle_answer_panel()
	progress_speech_bubble()

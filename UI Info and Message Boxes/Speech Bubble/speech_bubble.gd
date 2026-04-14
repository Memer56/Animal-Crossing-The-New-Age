extends Control

const ANSWER_BUTTON = preload("uid://i341a276olk1")

@export var is_one_paragraph : bool = false
@onready var rich_text_label: RichTextLabel = $TextureRect/RichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $TextureRect/NameTag/Label
@onready var arrow_anim: AnimationPlayer = $ArrowAnim
@onready var answer_panel: Panel = $TextureRect/AnswerPanel
@onready var v_box_container: VBoxContainer = $TextureRect/AnswerPanel/VBoxContainer

var text_to_say : Array
var text_index : int = 1
var num_of_paragraphs : int
## this variable determines if and where a question was asked, it may contain slot data info if an item is being passed
var question_at_indexes : Array
var response_types : Array
var question_result : bool = false
var item_to_be_given : SlotData
var answer_types : Array = ["Yes or No"]
var answer_index : int = 0
var allow_text_progression : bool = true

func _ready() -> void:
	arrow_anim.play("arrow")
	EventBus.display_speech_bubble.connect(display_text)

func display_text(new_text_array : Array, npc_name : String, _question_at_indexes : Array, _item_to_be_given : SlotData):
	#Grab data and display first text
	num_of_paragraphs = new_text_array.size()
	text_to_say = new_text_array
	text_index = 0
	question_at_indexes = _question_at_indexes
	item_to_be_given = _item_to_be_given
	if num_of_paragraphs > 1:
		is_one_paragraph = false
	else:
		is_one_paragraph = true
	clear_previous_text()
	animation_player.play("anim")
	rich_text_label.append_text(text_to_say[0])
	label.text = npc_name
	if question_at_index():
		toggle_answer_panel()

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			progress_speech_bubble()

func progress_speech_bubble():
	if !answer_panel.visible:
		text_index += 1
		clear_previous_text()
		if text_index < text_to_say.size() and allow_text_progression:
			rich_text_label.append_text(text_to_say[text_index])
			print(text_index)
			if question_at_index():
				toggle_answer_panel()
		else:
			hide_speech_bubble()
	else:
		print("can't close this, answer panel is active")

func question_at_index() -> bool:
	for index in question_at_indexes:
		if text_index == index:
			return true
	return false

func handle_question_result(button_name : String):
	match button_name:
		#### Tom Nook Answers ####
		"what should I do?":
			pass
		"About my home___":
			toggle_answer_panel()
			#text_index is being subtracted due to being increased when progress_speech_bubble() is called
			if EventBus.loan_balance <= 0:
				#House can be upgraded
				text_index = (4 - 1)
				BuildManager.home_can_upgrade = true
				EventBus.loan_balance = 1200000
				EventBus.player_is_debt_free = false
			else:
				#House cannot be upgraded
				text_index = (3 - 1)
			progress_speech_bubble()
			#Allows the text to progress first before being denied the ability to progress
			await get_tree().create_timer(0.4).timeout
			allow_text_progression = false
		"I'm good":
			toggle_answer_panel()
			hide_speech_bubble()
		
		#### Nook's Cranny Answers ####
		"I'll take it!":
			if !EventBus.savings_balance >= item_to_be_given.item_data.price:
				clear_previous_text()
				toggle_answer_panel()
				rich_text_label.append_text("Sorry, it looks like you can't afford this item.")
			else:
				clear_previous_text()
				toggle_answer_panel()
				rich_text_label.append_text("Thank you for buying!")
				EventBus.player.hotbar_inventory_data.add_to_inventory(item_to_be_given)
				EventBus.current_shop_interact_object.has_been_sold = true
				EventBus.current_shop_interact_object.set_display_to_sold()
		"No thanks":
			toggle_answer_panel()
			hide_speech_bubble()

func give_player_debt() -> int:
	var new_debt : int
	return 10

func hide_speech_bubble():
	animation_player.play_backwards("anim")
	clear_previous_text()
	allow_text_progression = true

func clear_previous_text():
	rich_text_label.text = ""

func toggle_answer_panel():
	if answer_panel.visible:
		answer_panel.hide()
		for child in v_box_container.get_children():
			child.queue_free()
	else:
		#Makes the panel wait before showing if in shop
		if label.text == "Timmy":
			await get_tree().create_timer(1.0).timeout
		answer_panel.show()
		spawn_answer_button()

func spawn_answer_button():
	var npc_dialogue = NpcDialogue.new()
	var chosen_answer_array : Array
	# This uses label.text because I cba making another var to store the npc name
	match label.text:
		"Tom":
			chosen_answer_array = npc_dialogue.tom_answer_button_options_1
		"Timmy":
			chosen_answer_array = npc_dialogue.timmy_answer_button_options
	
	if chosen_answer_array:
		for _button_name in chosen_answer_array:
			var new_button : Button = ANSWER_BUTTON.instantiate()
			v_box_container.add_child(new_button)
			new_button.pressed.connect(_answer_button_pressed.bind(new_button))
			new_button.text = _button_name
			new_button.name = _button_name

func _answer_button_pressed(button : Button):
	handle_question_result(button.name)

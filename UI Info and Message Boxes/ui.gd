extends CanvasLayer

const CONFIRM_MESSAGE = preload("uid://btn78ebu7dnjd")

func _ready() -> void:
	EventBus.trigger_confirm_message.connect(spawn_confirm_message_box)

func spawn_confirm_message_box(main_text : String):
	var msg_box = CONFIRM_MESSAGE.instantiate()
	msg_box.text = main_text
	msg_box.is_for_placing_object = true
	add_child(msg_box)

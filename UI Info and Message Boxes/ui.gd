extends CanvasLayer

const CONFIRM_MESSAGE = preload("uid://btn78ebu7dnjd")
const CHEAT_MENU_UI = preload("uid://ww7phe1tiqck")

@onready var inventory_interface: Control = $InventoryInterface

func _ready() -> void:
	EventBus.trigger_confirm_message.connect(spawn_confirm_message_box)

func spawn_confirm_message_box(main_text : String):
	var msg_box = CONFIRM_MESSAGE.instantiate()
	msg_box.text = main_text
	msg_box.is_for_placing_object = true
	add_child(msg_box)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ToggleCheatMenu"):
		if !CheatManager.cheat_menu_displayed:
			var cheat_menu = CHEAT_MENU_UI.instantiate()
			# This allows the PauseMenu to be clickable due to scenetree order
			inventory_interface.add_sibling(cheat_menu)
			CheatManager.cheat_menu_displayed = true
		else:
			CheatManager.remove_ui.emit()
			CheatManager.cheat_menu_displayed = false

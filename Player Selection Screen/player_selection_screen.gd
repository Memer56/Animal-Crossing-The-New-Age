extends Control

@onready var player_creation_h_box: HBoxContainer = $BG/Panel/Panel/PlayerCreationHBox


var player_text_tutorial_is_done : bool = false

#func _ready() -> void:
	#var text : Array = [
		#"Welcome to the selection screen!",
		#"On this screen you will be able to enter your name and select your skin and hair colour...",
		#"you can also select which island you wish to play on but...",
		#"remember, once this island is selected you cannot change it!",
		#"Go ahead and choose your player details and island and have fun!"
	#]
	#EventBus.display_speech_bubble.emit(text, "Info", [], null)

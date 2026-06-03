extends Resource
class_name NpcDialogue
## Index of an npc's array indicates where the player is of possible interactions

@export var tom_dialogue : Array = [
	[["I'm fucking [color=red]Tom[/color]", "What the fuck do you want?", "What should you do", "I'm sorry, no home upgrade for you", "Yes yes, enjoy the bigger house"], "Tom", [1], null]
]

@export var tom_answer_button_options_1 : Array = ["what should I do?", "About my home...", "I'm good"]

@export var bunnie_dialogue : Array = [
	[["Hello, I'm [color=blue]<Insert fucking name>[/color], who are you?"], "Bunnie", [], null]
]
@export var bob_dialogue : Array = [
	[["Why hello [color=green]" + EventBus.player_customisations[0] + "[/color]! I'm a [color=purple]CAT[/color]! You don't look like a cat", "I do need a potato...", "Can I take [color=blue]100,000[/color] bells?"], "Bob", [], null]
]

@export var timmy_answer_button_options : Array = ["I'll take it!", "No thanks"]

func get_correct_dialogue(npc_name : String, dialogue_index : int) -> Array:
	var dialogue_array : Array
	match npc_name:
		"Tom":
			dialogue_array = tom_dialogue[dialogue_index]
		"Timmy":
			pass
		"Tommy":
			pass
		"Bunnie":
			dialogue_array = bunnie_dialogue[dialogue_index]
		"Bob":
			dialogue_array = bob_dialogue[dialogue_index]
	
	return dialogue_array

extends ItemData
class_name ItemDataConsumable


@export var heal_value : int

func use(_target) -> void:
	if heal_value != 0:
		EventBus.player.eat_consumable()

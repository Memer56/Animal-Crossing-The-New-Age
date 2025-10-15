extends ItemData
class_name ItemDataPlant

func use(target) -> void:
	if EventBus.can_place:
		target.plant_sapling(self)

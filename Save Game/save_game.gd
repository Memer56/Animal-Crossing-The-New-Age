extends Resource
class_name SaveGame

const SAVE_GAME_PATH_PLAYER = "user://Game Data/player_data"
const SAVE_GAME_PATH_BUILDINGS = "user://Game Data/buildings_data"

## Things to save
@export var inventory : InventoryData
@export var hotbar_inventory : InventoryData
@export var bells : int
@export var house_level : int # 0 = Tent, 1 = House etc
@export var building_info : Dictionary[String, Vector3]

## Funtions to save data
func write_savegame_data():
	var save_path = str(SAVE_GAME_PATH_PLAYER + " " + ProjectSettings.get_setting("application/config/version") + '.tres')
	ResourceSaver.save(self, save_path)

static func save_exists():
	var save_path = str(SAVE_GAME_PATH_PLAYER + " " + ProjectSettings.get_setting("application/config/version") + '.tres')
	return ResourceLoader.exists(save_path)

static func load_savegame_data():
	var save_path = str(SAVE_GAME_PATH_PLAYER + " " + ProjectSettings.get_setting("application/config/version") + '.tres')
	return ResourceLoader.load(save_path, "", 2)

## Functions to save building data
func write_savegame_data_buildings():
	var save_path = str(SAVE_GAME_PATH_BUILDINGS + " " + ProjectSettings.get_setting("application/config/version") + '.tres')
	ResourceSaver.save(self, save_path)

static func save_exists_buildings():
	var save_path = str(SAVE_GAME_PATH_BUILDINGS + " " + ProjectSettings.get_setting("application/config/version") + '.tres')
	return ResourceLoader.exists(save_path)

static func load_savegame_data_buildings():
	var save_path = str(SAVE_GAME_PATH_BUILDINGS + " " + ProjectSettings.get_setting("application/config/version") + '.tres')
	return ResourceLoader.load(save_path, "", 2)

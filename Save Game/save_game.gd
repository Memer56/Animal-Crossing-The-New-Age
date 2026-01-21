extends Resource
class_name SaveGame

const SAVE_GAME_PATH_PLAYER = "user://Game Data/save_file"

var time = Time.get_datetime_dict_from_system()

## Things to save
@export var inventory : InventoryData
@export var hotbar_inventory : InventoryData
@export var bells : int
@export var house_level : int # 0 = Tent, 1 = House etc
@export var exterior_object_info : Dictionary[String, Vector3]
@export var interior_object_info : Dictionary[String, Vector3]
@export var this_save_date = str("%02d:%02d:%02d %02d:%02d:%02d" % [time.day, time.month, time.year, time.hour, time.minute, time.second])
@export var game_version = ProjectSettings.get_setting("application/config/version")

## Funtions to save data
func write_savegame_data(id : String):
	var save_path = str(SAVE_GAME_PATH_PLAYER+ " " + id + '.tres')
	ResourceSaver.save(self, save_path)

static func save_exists(id : String):
	var save_path = str(SAVE_GAME_PATH_PLAYER + " " + id + '.tres')
	return ResourceLoader.exists(save_path)

static func load_savegame_data(id : String):
	var save_path = str(SAVE_GAME_PATH_PLAYER + " " + id + '.tres')
	return ResourceLoader.load(save_path, "", 2)

static func delete_savegame(id : String):
	var save_path_player = str(SAVE_GAME_PATH_PLAYER + " " + id + '.tres')
	DirAccess.remove_absolute(save_path_player)

#################### Functions to save and load json id files ###################
#func write_json_file(save_id : String):
	#var data : Array = [save_id]
	#var save_path = str(SAVE_GAME_PATH_JSON + '.json')
	#var file = FileAccess.open(save_path, FileAccess.WRITE)
	#if not file:
		#push_error("Error SaveGame.gd --- File was not valid")
		#return
	#
	#var json_text = JSON.stringify(data)
	#file.store_string(json_text)
	#file.close()
#
#func json_file_exists():
	#var save_path = str(SAVE_GAME_PATH_JSON + '.json')
	#var file = FileAccess.open(save_path, FileAccess.READ)
	#if file:
		#return true
	#return false
#
#func read_json_file():
	#var existing_data : Array
	#var save_path = str(SAVE_GAME_PATH_JSON + '.json')
	#var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	#if file:
		#var file_contents = file.get_as_text()
		#var parse_result = JSON.parse_string(file_contents)
		#
		#if parse_result:
			#existing_data = parse_result
		#file.close()
	#return existing_data
#
#func update_json_file(save_id : String, is_deleting : bool):
	#var existing_data : Array
	#var save_path = str(SAVE_GAME_PATH_JSON + '.json')
	#var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	#if file:
		#var file_contents = file.get_as_text()
		#var parse_result = JSON.parse_string(file_contents)
		#
		#if parse_result:
			#existing_data = parse_result
		#file.close()
	#
	#if is_deleting:
		#var id_index = existing_data.find(save_id)
		#existing_data.remove_at(id_index)
	#else:
		#if existing_data.has(save_id):
			#return
		#else:
			#existing_data.append(save_id)
		#
	#var write_file = FileAccess.open(save_path, FileAccess.WRITE)
	#if write_file:
		#write_file.store_string(JSON.stringify(existing_data))
		#write_file.close()

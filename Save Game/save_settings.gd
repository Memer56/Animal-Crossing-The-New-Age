extends Resource
class_name SaveSettings

const SAVE_SETTINGS_PATH = "user://Game Data/Settings/settings"

var time = Time.get_datetime_dict_from_system()

@export var sound_settings : Array[float]
@export var this_save_date = str("%02d:%02d:%02d %02d:%02d:%02d" % [time.day, time.month, time.year, time.hour, time.minute, time.second])
@export var game_version = ProjectSettings.get_setting("application/config/version")

## Funtions to save data
func write_savegame_data():
	var save_path = str(SAVE_SETTINGS_PATH + '.tres')
	ResourceSaver.save(self, save_path)

static func save_exists():
	var save_path = str(SAVE_SETTINGS_PATH + '.tres')
	return ResourceLoader.exists(save_path)

static func load_savegame_data():
	var save_path = str(SAVE_SETTINGS_PATH + '.tres')
	return ResourceLoader.load(save_path, "", 2)

static func delete_savegame():
	var save_settings_path = str(SAVE_SETTINGS_PATH + '.tres')
	DirAccess.remove_absolute(save_settings_path)

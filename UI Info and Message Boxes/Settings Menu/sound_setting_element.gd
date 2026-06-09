extends Control

@onready var setting_name_label: Label = $HBoxContainer/VBoxContainer/SettingNameLabel
@onready var setting_value_label: Label = $HBoxContainer/SettingValueLabel
@export var setting_name : String
@export var audio_bus_name : StringName
@onready var h_slider: HSlider = $HBoxContainer/VBoxContainer/HSlider

var bus_index : int
var save_settings : SaveSettings

func _ready() -> void:
	setting_name_label.text = setting_name
	bus_index = AudioServer.get_bus_index(audio_bus_name)
	if SaveSettings.save_exists() == false:
		var audio_level = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
		h_slider.value = audio_level * 100
		save_sound_settings()
	else:
		load_saved_value()
	


func _on_h_slider_value_changed(value: float) -> void:
	var save = SaveSettings.new()
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100))
	var label_value : int = round(value)
	setting_value_label.text = str(label_value) + "%"
	EventBus.sound_settings[bus_index] = value
	save.sound_settings = EventBus.sound_settings
	save_sound_settings()

func save_sound_settings():
	var save = SaveSettings.new()
	save.sound_settings = EventBus.sound_settings
	save.write_savegame_data()

func load_saved_value():
	var settings = SaveSettings.load_savegame_data()
	EventBus.sound_settings = settings.sound_settings
	var value = EventBus.sound_settings[bus_index] / 100
	var label_value : int = int(value * 100)
	AudioServer.set_bus_volume_db(bus_index, value)
	h_slider.value = label_value
	setting_value_label.text = str(label_value) + "%"

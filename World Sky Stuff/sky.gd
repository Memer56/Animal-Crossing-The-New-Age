extends Node3D

@export var allow_day_night_cycle : bool = true
@export var day_length : float = 1000.0
@export var start_time : float = 0.3
@export var sun_colour : Gradient
@export var sun_intensity : Curve
@export var moon_colour : Gradient
@export var moon_intensity : Curve
@export var sky_top_colour : Gradient
@export var sky_bottom_colour : Gradient
@export var sun_scatter : Gradient
@export var cloud_light : Gradient
@export var cloud_shadow_intensity : Curve
@export var ambient_light_intensity : Curve
@export var star_intensity : Curve
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var time_rate : float
var save : SaveGame

func _ready() -> void:
	save = SaveGame.load_savegame_data(EventBus.current_save_file_id)
	if allow_day_night_cycle:
		time_rate = 1.0 / day_length
	if !EventBus.game_is_new_save:
		EventBus.world_time = save.world_time
	else:
		EventBus.world_time = start_time

func _physics_process(delta: float) -> void:
	EventBus.world_time += time_rate * delta
	
	if EventBus.world_time >= 1.0:
		EventBus.world_time = 0.0
	
	if EventBus.world_time >= 0.03 and EventBus.world_time <= 0.15:
		EventBus.service_buildings_closed = true
		if EventBus.service_buildings_lights_on:
			EventBus.service_buildings_lights_on = false
			EventBus.toggle_service_buildings_lights.emit(false)
	else:
		EventBus.service_buildings_closed = false
	
	if EventBus.world_time >= 0.9:
		if !EventBus.service_buildings_lights_on:
			if !EventBus.service_buildings_closed:
				EventBus.service_buildings_lights_on = true
				EventBus.toggle_service_buildings_lights.emit(true)
	
	sun.rotation_degrees.x = EventBus.world_time * 360 + 90
	sun.light_color = sun_colour.sample(EventBus.world_time)
	sun.light_energy = sun_intensity.sample(EventBus.world_time)
	
	moon.rotation_degrees.x = EventBus.world_time * 360 + 270
	#moon.light_color = moon_colour.sample(time)
	#moon.light_energy = moon_intensity.sample(time)
	
	sun.visible = sun.light_energy > 0
	moon.visible = moon.light_energy > 0
	
	world_environment.environment.sky.sky_material.set("shader_parameter/top_color", sky_top_colour.sample(EventBus.world_time))
	world_environment.environment.sky.sky_material.set("shader_parameter/bottom_color", sky_bottom_colour.sample(EventBus.world_time))
	world_environment.environment.sky.sky_material.set("shader_parameter/sun_scatter", sun_scatter.sample(EventBus.world_time))
	world_environment.environment.sky.sky_material.set("shader_parameter/clouds_light_color", cloud_light.sample(EventBus.world_time))
	world_environment.environment.sky.sky_material.set("shader_parameter/clouds_shadow_intensity", cloud_shadow_intensity.sample(EventBus.world_time))
	world_environment.environment.sky.sky_material.set("shader_parameter/stars_intensity", star_intensity.sample(EventBus.world_time))
	world_environment.environment.ambient_light_energy = ambient_light_intensity.sample(EventBus.world_time)

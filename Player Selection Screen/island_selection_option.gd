extends Control

@export var island_image : Texture
@export var island_name : String
@export var island_scene : String
@export var normal_stylebox : StyleBox
@export var hover_stylebox : StyleBox
@export var pressed_stylebox : StyleBox
@onready var texture_rect: TextureRect = $Panel/VBoxContainer/TextureRect
@onready var label: Label = $Panel/VBoxContainer/Label
@onready var panel: Panel = $Panel


func _ready() -> void:
	texture_rect.texture = island_image
	label.text = island_name


func _on_panel_mouse_entered() -> void:
	panel.add_theme_stylebox_override("panel", hover_stylebox)


func _on_panel_mouse_exited() -> void:
	panel.add_theme_stylebox_override("panel", normal_stylebox)


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			panel.add_theme_stylebox_override("panel", pressed_stylebox)
			if island_scene:
				print("Island scene path : ", island_scene)
	else:
		panel.add_theme_stylebox_override("panel", hover_stylebox)

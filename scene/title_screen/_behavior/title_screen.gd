class_name TitleScreen
extends Node2D

@export_file("*tscn.")
var next_scene: String

signal scene_change_requested(scene: PackedScene)

@onready
var play_button: Button = $PlayButton

func _ready() -> void:
	play_button.grab_focus()
	play_button.pressed.connect(_on_play_button_pressed, CONNECT_ONE_SHOT)
	
	
func _on_play_button_pressed() -> void:
	scene_change_requested.emit(load(next_scene))

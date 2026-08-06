class_name TitleScreen
extends Node2D

@export
var next_scene: PackedScene

@onready
var play_button: Button = $PlayButton

func _ready() -> void:
	play_button.grab_focus()
	play_button.pressed.connect(_on_play_button_pressed, CONNECT_ONE_SHOT)
	
	
func _on_play_button_pressed() -> void:
	GameState.game.change_scene(next_scene)

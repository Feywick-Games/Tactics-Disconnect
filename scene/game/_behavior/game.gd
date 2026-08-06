class_name Game
extends Node

var _current_scene: Node

@onready
var level_viewport: SubViewport = $LevelViewportContainer/LevelViewport
@onready
var viewport_container: SubViewportContainer = $LevelViewportContainer

func _ready() -> void:
	GameState.game = self
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_current_scene = level_viewport.get_child(0)
	
	
func change_scene(scene: PackedScene) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(viewport_container, "modulate:a", 0, 1)
	tween.play()
	await tween.finished
	tween.stop()
	_current_scene.queue_free()
	_current_scene = scene.instantiate()
	if _current_scene is Level:
		_prep_level(_current_scene)
	level_viewport.add_child(_current_scene)
	_current_scene.set_process(false)
	tween.tween_property(viewport_container, "modulate:a", 1, 1)
	tween.play()
	await tween.finished
	_current_scene.set_process(true)
	

func _prep_level(level: Level) -> void:
	level.ui = $CombatUI

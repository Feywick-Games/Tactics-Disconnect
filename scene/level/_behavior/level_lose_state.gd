class_name LevelLoseState
extends LevelState

func enter() -> void:
	super.enter()
	_level.lose()
	GameState.game.change_scene(_level.failure_scene)

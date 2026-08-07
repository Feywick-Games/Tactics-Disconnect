class_name LevelLoseState
extends LevelState

func enter() -> void:
	super.enter()
	print("you lose!!")
	GameState.game.change_scene(_level.failure_scene)

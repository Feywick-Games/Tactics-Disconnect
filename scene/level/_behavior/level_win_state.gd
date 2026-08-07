class_name LevelWinState
extends LevelState

func enter() -> void:
	super.enter()
	print("you win")
	GameState.game.change_scene(_level.success_scene)

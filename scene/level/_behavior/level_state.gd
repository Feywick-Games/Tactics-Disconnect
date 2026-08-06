class_name LevelState
extends State

var _level: Level

func enter() -> void:
	_level = state_machine.state_owner as Level

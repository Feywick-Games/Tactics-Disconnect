class_name CharacterIdleState
extends State

var _character: Character

func enter() -> void:
	_character = state_machine.state_owner as Character

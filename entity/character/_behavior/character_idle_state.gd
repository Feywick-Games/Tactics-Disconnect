class_name CharacterIdleState
extends State

var _character: Character

func enter() -> void:
	_character = state_machine.state_owner as Character
	# TODO: Replace with combat idle
	_character.animator.play_directional("idle", Vector2.ZERO)
	_character.health_bar.hide()
	for reaction: Reaction in _character.reactions:
		reaction.processed = false

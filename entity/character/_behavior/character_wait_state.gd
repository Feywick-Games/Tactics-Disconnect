class_name CharacterWaitState
extends State

var _character: Character
var _turn_data: TurnData
var _react_ready := false

func _init(turn_data: TurnData) -> void:
	_turn_data = turn_data


func enter() -> void:
	_character = state_machine.state_owner as Character
	# TODO: Replace with combat idle
	_character.animator.play_directional("idle", Vector2.ZERO)
	_character.health_bar.hide()
	_character.clear_expired_statuses()




func update(_delta : float) -> State:
	if _turn_data.active_skill_state and not _character in _turn_data.active_skill_state.targets and _character.health_bar.visible:
		_character.health_bar.hide()
	_character.display_modified_status(_turn_data.active_skill_state)
	if _character.can_react(_turn_data):
		if not _react_ready:
			_react_ready = true
			_character.play_dialogue("exclamation")
	else:
		_react_ready = false
		_character.play_dialogue()
	
	return


func exit() -> void:
	_character.health_bar.hide()
	_character.play_dialogue()
	_character.highlight(false)

class_name ReactionState
extends State

var _character: Character
var _reaction: Reaction
var _target: Character
var _reaction_data: PhaseData
var _reacted: bool
var _impact_time: float = 1.0
var _time_in_state: float

func _init(reaction: Reaction, character: Character, target: Character, turn_data: PhaseData) -> void:
	_reaction = reaction
	_character = character
	_target = target
	_reaction_data = turn_data
	

func _react() -> void:
	_reacted = true


func update(delta: float) -> State:
	if _reacted:
		_time_in_state = _time_in_state + delta
		if _time_in_state > _impact_time and PhaseData.Event.IMPACT not in _reaction_data.events:
			_reaction_data.events.append(PhaseData.Event.IMPACT)
		if not is_instance_valid(_target):
			return CharacterIdleState.new()
	return


func can_use(_skill: Skill, _actor: Character) -> bool:
	return false

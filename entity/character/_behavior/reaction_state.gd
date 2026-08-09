class_name ReactionState
extends State

signal impact

var _character: Character
var _reaction: Reaction
var _target: Character
var _reacted := false
var _impact_time: float = 1.0
var _time_in_state: float
var _success := false
var _impact_emitted := false
var _qte_pending := true


func _init(reaction: Reaction, character: Character, target: Character) -> void:
	_reaction = reaction
	_character = character
	_target = target


func _react() -> void:
	_reacted = true


func qte_succeeded(success: bool) -> void:
	_success = success
	_qte_pending = false


func update(delta: float) -> State:
	if not _qte_pending:
		if _success:
			if _target.state_machine.current_state is CharacterIdleState and not _reacted:
				_react()
			
			if _reacted:
				_time_in_state = _time_in_state + delta
			
			if _time_in_state > _impact_time and _reacted:
				impact.emit()
				_impact_emitted = true
			if not is_instance_valid(_target):
				return CharacterIdleState.new()
		else:
			return CharacterIdleState.new()
	return


func can_use(_skill: Skill, _actor: Character) -> bool:
	return false

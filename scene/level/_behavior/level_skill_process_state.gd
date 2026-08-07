class_name LevelSkillProcessState
extends LevelState

var _turn_data: PhaseData
var _reacting_units: Array[Character]
var _reaction_states: Array[ReactionState]
var _reaction_data: PhaseData
var _damage_states_processing: int
var _waiting: bool = false
var _colliding: bool = false


func _init(turn_data: PhaseData) -> void:
	_turn_data = turn_data


func enter() -> void:
	super.enter()
	var skill_state : SkillState = _level.active_unit.state_machine.current_state
	if skill_state is PushSkillState:
		_level.ui.push_progress.start((int(_level.active_unit.active_skill.push_position.length())))
		skill_state.mini_game = _level.ui.push_progress
	
	_damage_states_processing = _turn_data.targets.size()
	
	var units: Array[Character] = _turn_data.targets
	_reaction_data = PhaseData.new()
	for effected_unit: Character in units:
		for reacting_unit in _level.get_unit_list():
			if reacting_unit != _level.active_unit and reacting_unit != effected_unit:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit, _reaction_data)
					if reaction_state.can_use(_level.active_unit.active_skill, _level.active_unit):
						_reaction_states.append(reaction_state)
						_reacting_units.append(reacting_unit)
						_waiting = true


func update(_delta : float) -> State:
	if _level.active_unit.state_machine.current_state is CharacterIdleState and _turn_data.damage_states_processed == _damage_states_processing:
		if not _reaction_states.is_empty():
			return LevelReactionState.new(_reacting_units, _reaction_states,_reaction_data)
		else:
			return LevelSpawnState.new()
	if _waiting and PhaseData.Event.IMPACT in _turn_data.events:
		_on_impact()
	if _colliding and PhaseData.Event.COLLIDED in _turn_data.events:
		_on_collided()
	
	return


func _on_impact() -> void:
	_waiting = false
	if not _turn_data.damage_states[0] is PushDamageState:
		for i: int in range(len(_turn_data.targets)):
			_turn_data.targets[i].set_state(_turn_data.damage_states[i])
	else:
		_turn_data.targets[0].set_state(_turn_data.damage_states[0])
		_colliding = true


func _on_collided() -> void:
	_colliding = false
	for i: int in range(1, len(_turn_data.targets)):
		_turn_data.targets[i].set_state(_turn_data.damage_states[i])


func _damage_states_processed() -> bool:
	return false

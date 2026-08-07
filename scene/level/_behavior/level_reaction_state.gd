class_name LevelReactionState
extends LevelState

var _reaction_states: Array[ReactionState]
var _reacting_units: Array[Character]
var _current_reactor: Character
var _current_reaction_state: ReactionState
var _reaction_data: PhaseData
var _waiting := true


func _init(reacting_units: Array[Character], reaction_states: Array[ReactionState], reaction_data: PhaseData) -> void:
	_reacting_units = reacting_units
	_reaction_states = reaction_states
	_reaction_data = reaction_data


func update(_delta : float) -> State:
	if not _reaction_states.is_empty():
		if not _current_reactor or _current_reactor.state_machine.state is CharacterIdleState:
			_get_next_reaction()
		elif _reaction_data.damage_states_processed == _reaction_data.damage_states.size():
			return _check_unit_count()
	else:
		if _current_reactor:
			if _current_reactor.state_machine.current_state is CharacterIdleState and _reaction_data.damage_states_processed == _reaction_data.damage_states.size():
				return _check_unit_count()
		else:
			return _check_unit_count()
	if _waiting and PhaseData.Event.IMPACT in _reaction_data.events:
		_on_impact()
	return
	

func _get_next_reaction() -> void:
	var next_reaction: ReactionState = _reaction_states.pop_front()
	var next_actor: Character = _reacting_units.pop_front()
	next_actor.set_state(next_reaction)
	_current_reactor = next_actor
	_current_reaction_state = next_reaction


func _on_impact() -> void:
	_waiting = false
	for i: int in range(len(_reaction_data.targets)):
		_reaction_data.targets[i].set_state(_reaction_data.damage_states[i])


func _check_unit_count() -> State:
	var ally_count: int = _level.get_tree().get_node_count_in_group("ally")
	var enemy_count: int = _level.get_tree().get_node_count_in_group("enemy")
	
	if enemy_count == 0:
		var spawn_points : Array[SpawnPoint]
		for child: Node in _level.find_children("*", "SpawnPoint"):
			spawn_points.append(child as SpawnPoint)
		
		var spawns_remaining := false
		for spawn_point: SpawnPoint in spawn_points:
			if not spawn_point.spawn_data.is_empty():
				spawns_remaining = true
				break
		
		if not spawns_remaining:
			return LevelWinState.new()
	
	if ally_count == 0:
		return LevelLoseState.new()
	return LevelSpawnState.new()

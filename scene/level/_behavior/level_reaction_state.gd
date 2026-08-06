class_name LevelReactionState
extends LevelState

var _reaction_states: Array[ReactionState]
var _reacting_units: Array[Character]
var _current_actor: Character

func enter() -> void:
	super.enter()
	var units: Array[Character] = _level.get_unit_list()
	var effected_units: Array[Character]
	for unit: Character in units:
		if not unit.status.is_empty():
			effected_units.append(unit)
	
	for effected_unit: Character in effected_units:
		for reacting_unit in units:
			if reacting_unit != _level.active_unit:
				for reaction: Skill in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state.can_use():
						_reaction_states.append(reaction_state)
						_reacting_units.append(reacting_unit)
	

func update(_delta : float) -> State:
	if not _reaction_states.is_empty():
		if not _current_actor or _current_actor.state_machine.state is CharacterIdleState:
			_get_next_reaction()
		else:
			return LevelSpawnState.new()
	else:
		if _current_actor:
			if _current_actor.state_machine.current_state is CharacterIdleState:
				return LevelSpawnState.new()
		else:
			return LevelSpawnState.new()
	return
	

func _get_next_reaction() -> void:
	var next_reaction: ReactionState = _reaction_states.pop_front()
	var next_actor: Character = _reacting_units.pop_front()
	next_actor.set_state(next_reaction)
	_current_actor = next_actor


func check_unit_count() -> State:
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
			return
	
	if ally_count == 0:
		return
	return LevelSpawnState.new()

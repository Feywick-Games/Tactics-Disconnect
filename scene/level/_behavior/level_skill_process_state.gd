class_name LevelSkillProcessState
extends LevelState

var _reacting_units: Array[Character]
var _targets: Array[Character]

func enter() -> void:
	super.enter()
	
	var skill_state: SkillState = _level.active_unit.state_machine.current_state
	if skill_state is PushSkillState:
		_level.ui.push_progress.start((int(_level.active_unit.active_skill.push_position.length())))
		skill_state.mini_game = _level.ui.push_progress
	
	for effected_unit: Character in _level.get_unit_list():
		if effected_unit.state_machine.current_state is DamageState:
			_targets.append(effected_unit)
			for reacting_unit in _level.get_unit_list():
				if reacting_unit != _level.active_unit and reacting_unit != effected_unit:
					for reaction: Reaction in reacting_unit.reactions:
						var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
						if reaction_state.can_use(_level.active_unit.active_skill, _level.active_unit):
							_reacting_units.append(reacting_unit)
							reacting_unit.set_state(reaction_state)
							if reacting_unit is Ally:
								if reaction_state is CheerReactionState:
									_level.ui.reaction_qte_manager.dispatch_qtes(1,skill_state.impact_time)
									_level.ui.reaction_qte_manager.reacted.connect(skill_state.on_cheer)
								elif reaction_state is CollisionReactionState:
									_level.ui.reaction_qte_manager.dispatch_qtes(1, (skill_state as PushSkillState).push_time)
								elif reaction_state is GetBehindMeReactionState:
									_level.ui.reaction_qte_manager.dispatch_qtes(1, skill_state.impact_time)
									_level.ui.reaction_qte_manager.reacted.connect(skill_state.get_behind_me)
								elif reaction_state is CheapShotReactionState:
										_level.ui.reaction_qte_manager.dispatch_qtes(1, skill_state._character.animator.get_section_end_time())
								_level.ui.reaction_qte_manager.reacted.connect(reaction_state.qte_succeeded)
							else:
								reaction_state.qte_succeeded(true)
							break
						


func update(_delta : float) -> State:
	if not _is_skill_processing():
		return _check_unit_count()
	return


func _is_skill_processing() -> bool:
	var units_to_remove: Array[int]
	
	for i: int in range(len(_targets)):
		if not is_instance_valid(_targets[i]):
			units_to_remove.append(i)
	
	
	if not units_to_remove.is_empty():
		var new_target_list: Array[Character]
		for i:int in range(len(_targets)):
			if not i in units_to_remove:
				new_target_list.append(i)
		_targets = new_target_list
		
	for unit: Character in [_level.active_unit] + _reacting_units + _targets:
		if not unit.state_machine.current_state is CharacterIdleState:
			return true
	
	return false


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

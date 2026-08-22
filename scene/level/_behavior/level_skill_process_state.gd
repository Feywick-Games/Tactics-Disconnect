class_name LevelSkillProcessState
extends LevelState

var _reacting_units: Array[Character]
var _targets: Array[Character]
var _mini_game: MiniGame
var _qtes_dispatched := false
var _qte_callbacks: Array[Callable]


func enter() -> void:
	super.enter()
	_prep_skill_state()
	_set_reaction_states()


func update(_delta : float) -> State:
	if (not _mini_game or _mini_game.completed) and not _qtes_dispatched:
		_dispatch_qtes()
	if not _is_skill_processing():
		return _check_unit_count()
	return


func _prep_skill_state() -> void:
	var skill_state: SkillState = _level.active_unit.state_machine.current_state
	if _level.active_unit is Ally:
		if skill_state is PushSkillState:
			_mini_game = _level.ui.push_progress
			_level.ui.push_progress.start((int(_level.active_unit.active_skill.push_position.length())))
		elif skill_state is RangeSkillState:
			_mini_game = _level.ui.range_challege
			_level.ui.range_challege.start(_level.active_unit.current_tile, skill_state.target_tile)
		elif skill_state is MeleeSkillState:
			_mini_game = _level.ui.melee_combo
			_level.ui.melee_combo.start(skill_state.skill.aoe.size())
		if _mini_game:
			skill_state.mini_game = _mini_game
	else:
		var dummy_mini_game := MiniGame.new()
		dummy_mini_game.completed = true
		dummy_mini_game.value = 1
		dummy_mini_game.success = true
		skill_state.mini_game = dummy_mini_game


func _dispatch_qtes() -> void:
	for callback: Callable in _qte_callbacks:
		callback.call()
	
	_qtes_dispatched = true


func _set_reaction_states() -> void:
	var skill_state: SkillState = _level.active_unit.state_machine.current_state
	_targets = skill_state.targets
	
	for effected_unit: Character in _targets:
		var cheer_reacting_id: int = 0
		for reacting_unit in _level.get_unit_list():
			if reacting_unit != _level.active_unit and reacting_unit != effected_unit:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state.can_use(skill_state, _level.active_unit):
						if skill_state is PushSkillState and reaction_state is CheapShotReactionState:
							continue
						_reacting_units.append(reacting_unit)
						reacting_unit.set_state(reaction_state)
						if reacting_unit is Ally:
							if reaction_state is CheerReactionState:
								reaction_state.id = cheer_reacting_id
								cheer_reacting_id += 1
								var cheer_reaction_state := reaction_state as CheerReactionState
								_qte_callbacks.append(_level.ui.reaction_qte_manager.dispatch_qtes.bind(
									reacting_unit.get_screen_transform().get_origin(), 
									true if reacting_unit.global_position.y < effected_unit.global_position.y else false
									,skill_state.impact_time
								))
								if not _level.ui.reaction_qte_manager.reacted.is_connected(skill_state.on_cheer):
									_level.ui.reaction_qte_manager.reacted.connect(skill_state.on_cheer)
								_level.ui.reaction_qte_manager.reacted.connect(cheer_reaction_state.qte_succeeded)
							elif reaction_state is CollisionReactionState:
								_qte_callbacks.append(_level.ui.reaction_qte_manager.dispatch_qtes.bind(
									reacting_unit.get_screen_transform().get_origin(), 
									true if reacting_unit.global_position.y < effected_unit.global_position.y else false,
									skill_state.impact_time + (skill_state as PushSkillState).push_time
								))
							elif reaction_state is GetBehindMeReactionState:
								_qte_callbacks.append(_level.ui.reaction_qte_manager.dispatch_qtes.bind(
									reacting_unit.get_screen_transform().get_origin(), 
									true if reacting_unit.global_position.y < effected_unit.global_position.y else false,
									skill_state.impact_time
								))
								_level.ui.reaction_qte_manager.reacted.connect(skill_state.get_behind_me)
							elif reaction_state is CheapShotReactionState:
								_qte_callbacks.append(_level.ui.reaction_qte_manager.dispatch_qtes.bind(
									reacting_unit.get_screen_transform().get_origin(), 
									true if reacting_unit.global_position.y < effected_unit.global_position.y else false,
									skill_state._character.animator.get_section_end_time()))
							if not _level.ui.reaction_qte_manager.reacted.is_connected(reaction_state.qte_succeeded):
								_level.ui.reaction_qte_manager.reacted.connect(reaction_state.qte_succeeded)
						else:
							reaction_state.qte_succeeded(true)
						break
	if _qte_callbacks.is_empty():
		_qtes_dispatched = true


func _is_skill_processing() -> bool:
	var units_to_remove: Array[int]
	
	for i: int in range(len(_targets)):
		if not is_instance_valid(_targets[i]):
			units_to_remove.append(i)
	
	
	if not units_to_remove.is_empty():
		var new_target_list: Array[Character]
		for i:int in range(len(_targets)):
			if not i in units_to_remove:
				new_target_list.append(_targets[i])
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
	
	

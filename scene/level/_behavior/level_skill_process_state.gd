class_name LevelSkillProcessState
extends LevelState

signal instant_dispatch_requested

var _reacting_units: Array[Character]
var _targets: Array[Character]
var _mini_game: MiniGame


func enter() -> void:
	super.enter()
	_prep_skill_state()
	_set_reaction_states()


func update(_delta : float) -> State:
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
			_mini_game.reset()
			skill_state.mini_game = _mini_game
	else:
		var dummy_mini_game := MiniGame.new()
		skill_state.mini_game = dummy_mini_game
		dummy_mini_game.ranking = MiniGame.Rank.NORMAL


func _set_reaction_states() -> void:
	var skill_state: SkillState = _level.active_unit.state_machine.current_state
	_targets = skill_state.targets
	
	for effected_unit: Character in _targets:
		for reacting_unit in _level.get_unit_list():
			if reacting_unit is Enemy and reacting_unit != _level.active_unit and reacting_unit != effected_unit:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state.can_use(skill_state, _level.active_unit):
						reaction_state.qte_succeeded(true)
						_reacting_units.append(reacting_unit)
						reacting_unit.set_state(reaction_state)
						break
	
	for effected_unit: Character in _targets:
		for reacting_unit in _level.get_unit_list():
			if reacting_unit is Ally and  reacting_unit != _level.active_unit and reacting_unit != effected_unit and reacting_unit not in _reacting_units:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state is CheerReactionState and reaction_state.can_use(skill_state, _level.active_unit):
						var mini_game_sig : Signal = instant_dispatch_requested
						
						if _mini_game:
							mini_game_sig = _mini_game.finished
						
						_level.ui.reaction_qte_manager.dispatch_qtes(
							  reacting_unit.get_screen_transform().get_origin()
							, mini_game_sig, skill_state.impact, [reaction_state.qte_succeeded, skill_state.on_cheer])

						if not _mini_game:
							mini_game_sig.emit()
						
						_reacting_units.append(reacting_unit)
						reacting_unit.set_state(reaction_state)
	
	
	for effected_unit: Character in _targets:
		for reacting_unit in _level.get_unit_list():
			if reacting_unit is Ally and reacting_unit != _level.active_unit and reacting_unit != effected_unit and reacting_unit not in _reacting_units:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state is CheapShotReactionState and reaction_state.can_use(skill_state, _level.active_unit):
						if skill_state is PushSkillState:
							continue
						_level.ui.reaction_qte_manager.dispatch_qtes(
							reacting_unit.get_screen_transform().get_origin(), 
							skill_state.impact, skill_state.exited, [reaction_state.qte_succeeded])
						_reacting_units.append(reacting_unit)
						reacting_unit.set_state(reaction_state)

	for effected_unit: Character in _targets:
		for reacting_unit in _level.get_unit_list():
			if reacting_unit is Ally and reacting_unit != _level.active_unit and reacting_unit != effected_unit and reacting_unit not in _reacting_units:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state is CollisionReactionState and reaction_state.can_use(skill_state, _level.active_unit):
						var push_skill_state := skill_state as PushSkillState
						_level.ui.reaction_qte_manager.dispatch_qtes(
							reacting_unit.get_screen_transform().get_origin(), 
							skill_state.impact, push_skill_state.target_collided, [reaction_state.qte_succeeded])
						_reacting_units.append(reacting_unit)
						reacting_unit.set_state(reaction_state)
	
	for effected_unit: Character in _targets:
		for reacting_unit in _level.get_unit_list():
			if reacting_unit is Ally and reacting_unit != _level.active_unit and reacting_unit != effected_unit and not reacting_unit in _targets and reacting_unit not in _reacting_units:
				for reaction: Reaction in reacting_unit.reactions:
					var reaction_state: ReactionState = reaction.state.new(reaction, reacting_unit, effected_unit)
					if reaction_state is GetBehindMeReactionState and reaction_state.can_use(skill_state, _level.active_unit):
						_level.ui.reaction_qte_manager.dispatch_qtes(
							reacting_unit.get_screen_transform().get_origin(), 
							instant_dispatch_requested, skill_state.impact, [reaction_state.qte_succeeded, skill_state.on_get_behind_me])
						reaction_state.exited.connect(skill_state.pause.bind(false))
						instant_dispatch_requested.emit()
						_reacting_units.append(reacting_unit)
						reacting_unit.set_state(reaction_state)


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
	
	

class_name PunishSkillState
extends SkillState

func update(delta:float) -> State:
	if mini_game and mini_game.completed and not _started:
		_hit_targets()
	elif _started and not _character.animator.is_playing():
		return CharacterIdleState.new()
	return super.update(delta)


func _hit_targets() -> void:
	_started = true
	_character.animator.play_directional(skill.character_animation, direction)
	_multiplier *= mini_game.value
	super._hit_targets()


func calc_skill_likelihood(turn_history: Array[TurnData.Serialization]) -> float:
	var this_turn_data: Array[TurnData.Serialization]
	var turn_history_search := turn_history.duplicate()
	for data: TurnData.Serialization in turn_history_search:
		while not turn_history_search.is_empty():
			var turn_data_seralized: TurnData.Serialization
			turn_data_seralized = turn_history_search.pop_back()
			if turn_data_seralized.turn_number == GameState.current_level.turn_number:
				this_turn_data.append(turn_data_seralized)
	for serialization: TurnData.Serialization in this_turn_data:
		for target: Character in targets:
			if serialization.active_character_node_name == target.name and serialization.special_used:
				return super.calc_skill_likelihood(turn_history)
	return 0

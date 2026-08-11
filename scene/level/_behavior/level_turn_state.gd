class_name LevelTurnState
extends LevelState

var _ordered_units: Array[Character]
var _turn_started := false
var _turn_data: TurnData


func enter() -> void:
	super.enter()
	
	if _level.unit_spawned:
		_ordered_units = _level.get_unit_list(false)
		_level.unit_spawned = false
	else:
		_ordered_units = _level.get_unit_list()
		var last_unit : Character = _ordered_units.pop_front()
		_ordered_units.append(last_unit)
	
	_level.active_unit = _ordered_units[0]
	
	_level.ui.start_turn(_ordered_units)
	_level.tracking_cam.follow(_level.active_unit)
	
	
func update(_delta : float) -> State:
	if _level.tracking_cam.in_position and not _turn_started:
		_turn_started = true
		_turn_data = TurnData.new(_level.active_unit)
		_level.active_unit.start_turn(_turn_data, _level.ui.display_skill_error_code)
		for unit: Character in _ordered_units:
			if unit != _level.active_unit:
				unit.set_state(CharacterWaitState.new(_turn_data))
	elif _turn_started:
		# TODO: move to be inside the player state to prevent the turn ending between tiles
		if _level.ui.battle_timer.timed_out:
			_level.active_unit.set_state(CharacterIdleState.new())
			return LevelSpawnState.new()
		
		if _level.active_unit.state_machine.current_state is SkillState:
			_level.ui.battle_timer.stop()
			return LevelSkillProcessState.new()
		elif _level.active_unit.state_machine.current_state is CharacterIdleState:
			return LevelSpawnState.new()
		
	return

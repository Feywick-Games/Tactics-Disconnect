class_name LevelTurnState
extends LevelState

var _ordered_units: Array[Character]
var _skill_highlight_range: SkillHighlightRange = SkillHighlightRange.new()
var _turn_started := false


func enter() -> void:
	super.enter()
	
	if _level.enemy_spawned:
		_ordered_units = _level.get_unit_list(false)
		_level.enemy_spawned = false
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
		_level.active_unit.start_turn(_skill_highlight_range, _level.ui.display_skill_error_code)
		for unit: Character in _ordered_units:
			if unit != _level.active_unit:
				unit.set_state(CharacterWaitState.new(_skill_highlight_range))
	elif _turn_started:
		if _level.ui.battle_timer.timed_out:
			_level.active_unit.set_state(CharacterIdleState.new())
			return LevelSpawnState.new()
		
		if _level.active_unit.state_machine.current_state is SkillState:
			_level.ui.battle_timer.stop()
			return LevelSkillProcessState.new()
		elif _level.active_unit.state_machine.current_state is CharacterIdleState:
			return LevelSpawnState.new()
		
	return

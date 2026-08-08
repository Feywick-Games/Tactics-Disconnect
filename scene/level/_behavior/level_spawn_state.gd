class_name LevelSpawnState
extends LevelState

var _spawn_points: Array[SpawnPoint]
var _spawns: Array[SpawnData]
var _spawned_unit: Character
var _next_state: State

func enter() -> void:
	super.enter()
	var ordered_units : Array [Character] = _level.get_unit_list()
	if _level.active_unit is Ally and ordered_units[1] is Enemy:
		_level.is_player_phase = false
	if _level.active_unit is Enemy and ordered_units[1] is Ally:
		_level.is_player_phase = true
		_level.spawn_processed = false
	
	if _level.ui.skill_progress.is_ready and _level.is_player_phase:
		_next_state = LevelSkillSelectState.new()
	else:
		_next_state = LevelTurnState.new()
	
	if _level.is_player_phase and not _level.spawn_processed:	
		_level.turn_number += 1
		_level.ui.skill_progress.increment()
		_level.spawn_processed = true
		for child: Node in _level.find_children("*", "SpawnPoint"):
			_spawn_points.append(child as SpawnPoint)
		_get_spawns_from_spawn_point()


func update(_delta : float) -> State:
	if _level.tracking_cam.in_position:
		var spawned: bool = false
		if _spawned_unit:
			spawned = not _spawned_unit.state_machine.current_state is CharacterCombatBeginState
			if spawned:
				if not _spawns.is_empty():
					_spawn_unit()
				else:
					if not _spawn_points.is_empty():
						_get_spawns_from_spawn_point() 
					else:
						return _next_state
		elif _spawns.is_empty():
			return _next_state
		else:
			_spawn_unit()
	
	return


func _get_spawns_from_spawn_point() -> void:
	while not _spawn_points.is_empty():
		var spawn_point: SpawnPoint = _spawn_points.pop_front()
		_spawns = spawn_point.get_units_from_trigger(SpawnData.Trigger.TURN_NUMBER, _level.turn_number)
		var enemies_remaining: int = _level.get_tree().get_node_count_in_group("enemies")
		_spawns.append_array(spawn_point.get_units_from_trigger(SpawnData.Trigger.ENEMIES_REMAINING, enemies_remaining))
		if not _spawns.is_empty():
			_level.tracking_cam.follow(spawn_point)
			break


func _spawn_unit() -> void:
	var spawn_data: SpawnData = _spawns.pop_front()
	_spawned_unit = spawn_data.character_scene.instantiate()
	_spawned_unit.global_position = spawn_data.spawn_global_position
	_spawned_unit.facing = spawn_data.facing
	_level.enemy_spawned = true
	_level.add_child(_spawned_unit)

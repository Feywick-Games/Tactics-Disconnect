class_name LevelSpawnState
extends LevelState

const SPAWN_TIME: float = .2

var _spawn_points: Array[SpawnPoint]
var _spawns: Array[SpawnData]
var _spawned_unit: Character
var _next_state: State
var _time_since_spawn: float = 0

func enter() -> void:
	super.enter()
	var next_unit : Character = null if _level.turn_number == -1 else _level.get_unit_list()[1]
	var first_player_unit: Character = null if _level.turn_number == -1 else _level.get_unit_list(false).front()
	if next_unit == first_player_unit:
		_level.turn_number += 1
		_level.ui.skill_progress.increment()
		for child: Node in _level.find_children("*", "SpawnPoint", false):
			_spawn_points.append(child as SpawnPoint)
		_get_spawns_from_spawn_point()
		if _level.ui.skill_progress.is_ready:
			_next_state = LevelSkillSelectState.new()
	if not _next_state:
		_next_state = LevelTurnState.new()


func update(_delta : float) -> State:
	if _level.tracking_cam.in_position:
		var spawned: bool = false
		if _spawned_unit:
			_time_since_spawn += _delta
			if _time_since_spawn > SPAWN_TIME:
				_time_since_spawn = 0
				spawned = true
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
		spawn_point.begin_process()
		_spawns = spawn_point.get_units_from_trigger(SpawnData.Trigger.TURN_NUMBER, _level.turn_number)
		if _level.turn_number > 0:
			var enemies_remaining: int = _level.get_tree().get_node_count_in_group("enemy")
			_spawns.append_array(spawn_point.get_units_from_trigger(SpawnData.Trigger.ENEMIES_REMAINING, enemies_remaining))
		var ally_positions: Array = _level.get_tree().get_nodes_in_group("ally").map(func(x: Ally) -> Vector2i: return x.current_tile)
		_spawns.append_array(spawn_point.get_units_from_trigger(SpawnData.Trigger.AOE, ally_positions))
		if not _spawns.is_empty():
			_level.tracking_cam.follow(spawn_point)
			break


func _spawn_unit() -> void:
	var spawn_data: SpawnData = _spawns.pop_front()
	_spawned_unit = spawn_data.character_scene.instantiate()
	_spawned_unit.global_position = spawn_data.spawn_global_position
	_spawned_unit.facing = spawn_data.facing
	_level.unit_spawned = true
	_level.add_child(_spawned_unit)
	_spawned_unit.skill_text_requested.connect(_level.ui.display_skill_text)

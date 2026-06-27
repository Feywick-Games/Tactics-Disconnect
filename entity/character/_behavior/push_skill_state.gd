class_name PushSkillState
extends SkillState

const TIME_PER_INCREMENT: float = .3
const TIME_TO_EXIT: float = 1.0
const TIME_TO_PUSH: float = 3.0

var _push_range: Array[Vector2i]
var _time_since_increment: float = 0
var _direction: Vector2i
var increment: int = 0
var _max_push_distance: int = 0
var _target_unit: Character
var _max_is_collision := false
var _o_target: Character
var _push_distance: int
var _tile_path: Array[Vector2i]
var _has_acted := false
var _astar: AStarGrid2D
var _is_pushing := false
var _time_not_pushed : float = 0

func enter() -> void:
	super.enter()
	_target_unit = GameState.current_level.grid.get_unit_from_tile(_target_tile)
	_push_range = [_target_tile]
	_direction =  Vector2i(Vector2(_target_tile - _character.current_tile).normalized().round())
	for effect: StatusEffect in _skill.status_effects:
		if effect.status == Combat.Status.PUSHED:
			_push_distance = effect.value
	
	for i in range(1, _push_distance + 1):
		if GameState.current_level.grid.region.has_point(_target_tile + (_direction * i)) \
		and not GameState.current_level.grid.is_point_solid(_target_tile + (_direction * i)):
			_max_push_distance += 1
		else:
			break
	
	var collision_point := _target_tile + (_direction * (_max_push_distance + 1))
	if GameState.current_level.grid.is_point_solid(collision_point):
		_max_is_collision = true
		
		var unit := GameState.current_level.grid.get_unit_from_tile(collision_point)
		
		if unit:
			_o_target = unit
	var skill_range = GameState.current_level.grid.request_range(_target_tile, 0, 
		_max_push_distance, Combat.RangeShape.CROSS, true, true
	)
	_astar = _target_unit.create_range_astar(skill_range, _max_push_distance)
	_tile_path = _astar.get_id_path(_target_tile, _target_tile + (_direction * _max_push_distance))
	
	_draw_range()


func _draw_range() -> void:
	GameState.current_level.draw_range(_push_range, Global.RETICLE_SPECIAL_1_ALTAS_COORDS)
	if (_direction * _max_push_distance) + _target_tile in _push_range:
		GameState.current_level.select_tile((_direction * _max_push_distance) + _target_tile)


func update(delta: float) -> State:
	var parent_state: State = super.update(delta)
	if parent_state:
		return parent_state
	
	if not _is_pushing:
		if Input.is_action_just_pressed("accept"):
			_is_pushing = true
		elif _time_not_pushed > TIME_TO_PUSH:
			_is_pushing = true
			_has_acted = true
	else:
		if not _has_acted:
			if Input.is_action_pressed("accept"):
				_time_since_increment += delta
				
				if _time_since_increment > TIME_PER_INCREMENT:
					_time_since_increment = 0
					increment += 1
					if increment > _max_push_distance:
						var unit = GameState.current_level.grid.get_unit_from_tile(_target_tile)
						var damage_state := DamageState.new(_skill, _character.facing,  _character.accuracy, _character.target_hit)
						unit.state_requested.emit(damage_state)
						if not _skill.is_animated: 
							_character.notify_impact()
						unit.action_processed.connect(end_turn)
						_has_acted = true
					else:
						_push_range.append(_target_tile + (_direction * increment))
						_draw_range()
				
			# TODO account for push animation
			else:
				var is_hit = _target_unit.is_hit(_character.accuracy)
				if is_hit:
					_tile_path = _tile_path.slice(0, increment + 1)
					var push_damage_state := PushDamageState.new(_tile_path, _o_target, _skill, _direction, INF, _character.target_hit)
					_target_unit.state_requested.emit(push_damage_state)
				else:
					var damage_state := DamageState.new(_skill, _direction, 0, _character.target_hit, 0)
					_target_unit.state_requested.emit(damage_state)
				if not _skill.is_animated:
					_character.notify_impact()
				_target_unit.action_processed.connect(end_turn)
				_has_acted = true
	return

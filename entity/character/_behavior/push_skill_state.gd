class_name PushSkillState
extends SkillState

const TIME_PER_INCREMENT: float = .3
const TIME_TO_EXIT: float = 1.0
const TIME_TO_PUSH: float = 3.0

var _push_range: Array[Vector2i]
var increment: int = 0
var _max_push_distance: int = 0
var _target_unit: Character
var _max_is_collision := false
var _o_target: Character
var _push_distance: int
var _push_tile_path: Array[Vector2i]
var _astar: AStarGrid2D
var pushing: bool = false
var push_time: float


func enter() -> void:
	super.enter()
	_target_unit = GameState.current_level.grid.get_unit_from_tile(_target_tile)
	_push_range = [_target_tile]
	_direction =  Vector2i(Vector2(_target_tile - _character.current_tile).normalized().round())
	_push_distance = round(skill.push_position.length())


func update(delta: float) -> State:
	if mini_game:
		if mini_game.completed and not pushing:
			pushing = true
			_on_minigame_completed()
		elif pushing and not _character.animator.is_playing():
			return CharacterIdleState.new() 
	return super.update(delta)


func _on_minigame_completed() -> void:
	_push_distance = round(mini_game.value * _push_distance)
	
	for i in range(1, _push_distance + 1):
		if GameState.current_level.grid.region.has_point(_target_tile + (_direction * i)) \
		and not GameState.current_level.grid.is_point_solid(_target_tile + (_direction * i)):
			_max_push_distance += 1
		else:
			break
	
	var collision_point := _target_tile + (_direction * (_max_push_distance + 1))
	if GameState.current_level.grid.region.has_point(collision_point) and \
	GameState.current_level.grid.is_point_solid(collision_point):
		_max_is_collision = true
		
		var unit := GameState.current_level.grid.get_unit_from_tile(collision_point)
		
		if unit:
			_o_target = unit
	var skill_range: RangeStruct = GameState.current_level.grid.request_range(_target_tile, 0, 
		_max_push_distance, Combat.RangeShape.CROSS, true, true
	)
	_astar = _target_unit.create_range_astar(skill_range, _max_push_distance)
	_push_tile_path = _astar.get_id_path(_target_tile, _target_tile + (_direction * _max_push_distance))
	var multiplier: float = 1
	
	var push_damage_state := PushDamageState.new(_push_tile_path, skill, _direction, _turn_data,multiplier)
	_turn_data.targets.append(_target_unit)
	_turn_data.damage_states.append(push_damage_state)
	
	if _o_target:
		var damage_state := DamageState.new(skill, _direction, _turn_data, multiplier)
		_turn_data.targets.append(_o_target)
		_turn_data.damage_states.append(damage_state)
		_turn_data.targets.append(_target_unit)
		damage_state = DamageState.new(skill, _direction, _turn_data, multiplier)
		_turn_data.damage_states.append(damage_state)
	
	push_time = float(_push_distance * Global.TILE_SIZE.x) / float(Global.PLAYER_SPEED)

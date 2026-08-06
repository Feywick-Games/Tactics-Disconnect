class_name PushSkillState
extends SkillState

const TIME_PER_INCREMENT: float = .3
const TIME_TO_EXIT: float = 1.0
const TIME_TO_PUSH: float = 3.0

var _push_range: Array[Vector2i]
var _direction: Vector2i
var increment: int = 0
var _max_push_distance: int = 0
var _target_unit: Character
var _max_is_collision := false
var _o_target: Character
var _push_distance: int
var _push_tile_path: Array[Vector2i]
var _astar: AStarGrid2D
var _pushing: bool = false


func enter() -> void:
	super.enter()
	mini_game_type = TurnData.MiniGameType.PUSH
	_target_unit = GameState.current_level.grid.get_unit_from_tile(_target_tile)
	_push_range = [_target_tile]
	_direction =  Vector2i(Vector2(_target_tile - _character.current_tile).normalized().round())
	_push_distance = round(skill.push_position.length())
	# play animation


func update(delta: float) -> State:
	super.update(delta)
	if mini_game:
		if mini_game.completed and not _pushing:
			_pushing = true
			_on_minigame_completed()
		elif _pushing and _target_unit.state_machine.current_state is CharacterIdleState:
			if not _o_target or _o_target.state_machine.current_state is CharacterIdleState:
				return CharacterIdleState.new() 
	return


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
	
	if _max_is_collision:
		multiplier = 1.5
	
	var push_damage_state := PushDamageState.new(_push_tile_path, _o_target, skill, _direction, _character.target_hit, multiplier)
	_target_unit.set_state(push_damage_state)
	if not skill.is_animated:
		await _character.get_tree().create_timer(.5).timeout
		_character.notify_impact()

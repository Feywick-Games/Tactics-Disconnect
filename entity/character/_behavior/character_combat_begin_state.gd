class_name CharacterCombatBeginState
extends State

const SNAP_DISTANCE: float = 1

var _target_position: Vector2
var _character: Character
var _direction: Vector2

func enter() -> void:
	_character = state_machine.state_owner as Character
	if _character is Ally:
		var world_pos: Vector2 = GameState.current_level.tile_to_world(
				GameState.current_level.get_nearest_available_tile(GameState.ally_order[0].global_position) + GameState.follow_layout[_character.follow_order]
			)
		_character.current_tile = GameState.current_level.get_nearest_available_tile(world_pos)
	else:
		_character.current_tile = GameState.current_level.get_nearest_available_tile(_character.global_position)
	_direction = (_character.global_position - GameState.current_level.tile_to_world(_character.current_tile)).normalized()
	GameState.current_level.update_unit_registry(_character.current_tile, _character)
	_target_position = GameState.current_level.tile_to_world(_character.current_tile)


func update(_delta: float) -> State:
	if _character.global_position.distance_to(_target_position) > SNAP_DISTANCE:
		_character.global_position += (_target_position - _character.global_position).normalized() * 2.0
		_character.global_position = _character.global_position.round()
	else:
		_character.ready_for_battle = true
		_character.global_position = GameState.current_level.tile_to_world(_character.current_tile)
		_character.animator.play_directional("idle", _direction)
		return CharacterCombatIdleState.new()
	
	return

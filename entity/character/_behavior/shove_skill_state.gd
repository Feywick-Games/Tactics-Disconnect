class_name ShoveSkillState
extends PushSkillState

var _moving := false
var _tile_path : Array[Vector2i]

func enter() -> void:
	super.enter()
	var offset_rotated := Vector2i(Vector2(skill.move_position).rotated(Vector2(_character.facing).angle()).round())
	var destination: Vector2i = _character.current_tile + offset_rotated
	_tile_path = GameState.current_level.grid.get_path_ignore_passables(_character.current_tile, destination)


func _on_push_progress_completed(value: float) -> void:
	_push_tile_path = _push_tile_path.slice(0, round(value * _push_tile_path.size()) + 1)
	var push_damage_state := PushDamageState.new(_push_tile_path, _o_target, skill, _direction, _character.target_hit)
	_target_unit.state_requested.emit(push_damage_state)
	if not _push_tile_path.is_empty() and _tile_path[-1] != _push_tile_path[-1]:
		_target_unit.action_processed.connect(_begin_movement)
	else:
		_target_unit.action_processed.connect(end_turn)
	if not skill.is_animated:
		_character.notify_impact()


func _begin_movement() -> void:
	_moving = true


func physics_update(delta : float) -> State:
	if _moving:
		_tile_path =  _character.process_movement(delta, _tile_path)
		if _tile_path.is_empty():
			_moving = false
			end_turn()
	return super.physics_update(delta)

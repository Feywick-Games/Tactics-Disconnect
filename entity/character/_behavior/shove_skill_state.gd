class_name ShoveSkillState
extends PushSkillState

var _moving := false
var _tile_path : Array[Vector2i]

func enter() -> void:
	super.enter()
	var offset_rotated := Vector2i(Vector2(skill.move_position).rotated(Vector2(_character.facing).angle()).round())
	var destination: Vector2i = _character.current_tile + offset_rotated
	_tile_path = GameState.current_level.grid.get_path_ignore_passables(_character.current_tile, destination)


func _hit_targets() -> void:
	super._hit_targets()
	if not _push_tile_path.is_empty() and _tile_path[-1] != _push_tile_path[-1]:
		_moving = true


func update(delta: float) -> State:
	var next_state := super.update(delta)
	if not _moving:
		return next_state
	return


func physics_update(delta : float) -> State:
	if _moving:
		if (not is_instance_valid(_target_unit) or _target_unit.state_machine.current_state is CharacterIdleState) \
		and ((not _o_target or not is_instance_valid(_o_target)) or _o_target.state_machine.current_state is CharacterIdleState):
			_tile_path =  _character.process_movement(delta, _tile_path, _character.move_animation)
			if _tile_path.is_empty():
				_moving = false
				_character.animator.play_directional("move_idle", _character.facing)
	return super.physics_update(delta)

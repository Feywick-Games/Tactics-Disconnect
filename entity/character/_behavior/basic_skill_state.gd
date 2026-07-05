class_name BasicSkillState
extends SkillState

var _direction: Vector2

func enter() -> void:
	super.enter()
	#TODO make directional animations
	_direction = VectorF.snap_direction(_target_tile - _character.current_tile)
	_character.animator.play_directional(_skill.character_animation, _direction)
	
	if not _skill.skill_animation.is_empty():
		_character.skill_animator.play_directional(_skill.skill_animation, _direction)
	_hit_targets(_skill.aoe, _skill.range_type)


func _hit_targets(aoe: Array[Vector2i], range_type: Combat.RangeType) -> void:
	_action_to_process = 0
	for tile_offset in aoe:
		var tile: Vector2i
		print("direction: " + str(rad_to_deg(_direction.angle())))
		var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(_direction.angle()).round())
		if range_type == Combat.RangeType.MELEE:
			tile = _character.current_tile + Vector2i(_direction) + offset_rotated
		else:
			tile = _target_tile + offset_rotated
		var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile)
		if unit:
			unit.action_processed.connect(end_turn)
			_action_to_process += 1
			var damage_state := DamageState.new(_skill, _direction, _character.accuracy, _character.target_hit)
			unit.state_requested.emit(damage_state)
	
	if not _skill.is_animated:
		await _character.get_tree().create_timer(1).timeout
		_character.notify_impact()


func can_use(target_tile: Vector2i) -> Global.SkillErrorCode:
	var target: Character
	
	for aoe_tile in _skill.aoe:
		var offset_rotated: = Vector2i(Vector2(aoe_tile).rotated(Vector2(_character.facing).angle()).round())
		target = GameState.current_level.grid.get_unit_from_tile(target_tile + offset_rotated)
		if target:
			break
	
	if not target:
		return Global.SkillErrorCode.NO_TARGET
	
	var can_move : bool = true
		
	if _skill.move_position != Vector2i.ZERO:
		can_move = false
		var move_tile: Vector2i  = _character.current_tile + _skill.move_position
		move_tile = Vector2i(Vector2(move_tile).rotated(Vector2(_character.facing).angle()).round())
		if (_skill.direct and GameState.current_level.grid.is_point_solid_ignore_unit(move_tile)) \
		or (not _skill.direct and GameState.current_level.grid.is_point_solid(move_tile)):
			can_move = true
	
	if not can_move:
		return Global.SkillErrorCode.MOVE_BLOCKED
	
	return Global.SkillErrorCode.OK

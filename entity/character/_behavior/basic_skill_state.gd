class_name BasicSkillState
extends SkillState


func enter() -> void:
	super.enter()
	_hit_targets(skill.aoe, skill.range_type)


func update(delta : float) -> State:
	if not _character.animator.is_playing() and PhaseData.Event.IMPACT in _turn_data.events:
		return CharacterIdleState.new()
	return super.update(delta)


func _hit_targets(aoe: Array[Vector2i], range_type: Combat.RangeType) -> void:
	for tile_offset in aoe:
		var tile: Vector2i
		var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(Vector2(_direction).angle()).round())
		if range_type == Combat.RangeType.MELEE:
			tile = _character.current_tile + Vector2i(_direction) + offset_rotated
		else:
			tile = _target_tile + offset_rotated
		var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile)
		if unit:
			_turn_data.targets.append(unit)
			var damage_state := DamageState.new(skill, _direction, _turn_data)
			_turn_data.damage_states.append(damage_state)

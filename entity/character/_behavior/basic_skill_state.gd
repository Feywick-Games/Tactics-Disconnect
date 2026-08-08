class_name BasicSkillState
extends SkillState

func enter() -> void:
	super.enter()
	_hit_targets()


func update(delta : float) -> State:
	if not _character.animator.is_playing() and _impact_emitted:
		return CharacterIdleState.new()
	return super.update(delta)


func _hit_targets() -> void:
	for tile_offset in skill.aoe:
		var tile: Vector2i
		var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(Vector2(_direction).angle()).round())
		if skill.range_type == Combat.RangeType.MELEE:
			tile = _character.current_tile + Vector2i(_direction) + offset_rotated
		else:
			tile = _target_tile + offset_rotated
		var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile)
		if unit:
			var damage_state := DamageState.new(skill, _direction, impact, _multiplier)
			unit.set_state(damage_state)
			
			

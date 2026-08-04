class_name BasicSkillState
extends SkillState

var _direction: Vector2

func enter() -> void:
	super.enter()
	#TODO make directional animations
	_direction = VectorF.snap_direction(_target_tile - _character.current_tile)
	_character.animator.play_directional(skill.character_animation, _direction)
	
	if not skill.skill_animation.is_empty():
		_character.skill_animator.play_directional(skill.skill_animation, _direction)
	_hit_targets(skill.aoe, skill.range_type)


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
			var damage_state := DamageState.new(skill, _direction, _character.target_hit)
			unit.set_state(damage_state)
	
	if not skill.is_animated:
		await _character.get_tree().create_timer(1).timeout
		_character.notify_impact()

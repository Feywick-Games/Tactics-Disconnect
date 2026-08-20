class_name RangeSkillState
extends SkillState

func update(delta:float) -> State:
	if mini_game and mini_game.completed and not _started:
		_hit_targets()
	elif _started and not _character.animator.is_playing() and _impact_emitted:
		return CharacterIdleState.new()
	return super.update(delta)


func _hit_targets() -> void:
	_started = true
	_character.animator.play_directional(skill.character_animation, direction)
	var range_challenge := mini_game as RangeChallenge
	_multiplier *= .5 if not range_challenge.success else 1.0
	super._hit_targets()

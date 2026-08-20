class_name MeleeSkillState
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
	_multiplier *= mini_game.value
	super._hit_targets()

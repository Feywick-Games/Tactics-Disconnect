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
	var multiplier : int = -Global.MINIGAME_FAILURE_MULTIPLIER if not mini_game.success else Global.MINIGAME_SUCCESS_MULTIPLIER
	skill.apply_damage_modifiers(multiplier)
	super._hit_targets()

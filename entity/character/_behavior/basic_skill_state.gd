class_name BasicSkillState
extends SkillState

func enter() -> void:
	super.enter()
	_started = true
	_hit_targets()
	_character.animator.play_directional(skill.character_animation, _character.facing)


func update(delta : float) -> State:
	if not _character.animator.is_playing() and _impact_emitted:
		return CharacterIdleState.new()
	return super.update(delta)

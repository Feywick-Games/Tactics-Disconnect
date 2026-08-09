class_name BasicSkillState
extends SkillState

func enter() -> void:
	super.enter()
	_started = true
	_hit_targets()


func update(delta : float) -> State:
	if not _character.animator.is_playing() and _impact_emitted:
		return CharacterIdleState.new()
	return super.update(delta)

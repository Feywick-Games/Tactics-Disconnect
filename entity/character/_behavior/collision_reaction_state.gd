class_name CollisionReactionState
extends ReactionState

var collided_skill: Skill = load("res://entity/character/_skill/collided_skill.tres")

var _emoted := false
var _turned := false

func update(delta: float) -> State:
	if not _emoted and _target.state_machine.current_state is PushDamageState:
		_emoted = true
		_character.play_dialogue("shock")
	
	if is_instance_valid(_target):
		if _impact_emitted and not _character.animator.is_playing():
			return CharacterIdleState.new()
	else:
		return CharacterIdleState.new()
	if not _qte_pending:
		if not _success:
			var dummy_signal: Signal
			return DamageState.new(collided_skill, _character.current_tile - _target.current_tile, dummy_signal, 1, true)
		else:
			if not _turned:
				_turned = true
				var direction: Vector2i = _target.current_tile - _character.current_tile
				_character.facing = direction
				_character.animator.play_directional(_reaction.character_animation, _character.facing)
	
	return super.update(delta)


func _react() -> void:
	super._react()
	_character.request_skill_text(_reaction.name)
	var direction: Vector2i = _target.current_tile - _character.current_tile
	
	var vfx :=  _reaction.visual_effect_scene.instantiate() as VisualEffect
	vfx.setup(direction, _target.current_tile, _reaction.aoe, [_target], _reaction.visual_effect_targets_only, impact)
	GameState.current_level.add_child(vfx)
	
	_character.facing = direction
	_character.animator.play_directional(_reaction.character_animation, _character.facing)
	_impact_time = _character.get_impact_time(_character.animator.current_animation)
	var damage_state := DamageState.new(_reaction, direction, impact)
	_target.set_state(damage_state)



func can_use(skill_state: SkillState, _actor: Character) -> bool:
	if not skill_state.skill.status_effects.filter(func(x:StatusEffect) -> bool: return x.status == Combat.Status.PUSHED).is_empty():
		var push_skill_state := skill_state as PushSkillState
		var terminus: Vector2i = push_skill_state.target_tile + (push_skill_state.direction * push_skill_state.max_push_distance)
		var start: Vector2i = push_skill_state.target_tile + push_skill_state.direction
		if start == _character.current_tile:
			return true
		var path: Array[Vector2i] = GameState.current_level.grid.get_id_path(start, terminus)
		if _character.current_tile - push_skill_state.direction in path:
			return true
	return false

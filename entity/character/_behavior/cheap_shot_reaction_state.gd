class_name CheapShotReactionState
extends ReactionState


func update(delta: float) -> State:
	if is_instance_valid(_target):
		if _impact_emitted and not _character.animator.is_playing() and not _character.is_dialogue_playing():
			return CharacterIdleState.new()
	else:
		return CharacterIdleState.new()
	return super.update(delta)


func _impact()-> void:
	super._impact()
	_character.play_actor_status(true, false, false, true)


func _react() -> void:
	super._react()
	_character.request_skill_text(_reaction.name)
	var direction: Vector2i = _target.current_tile - _character.current_tile
	
	var vfx :=  _reaction.visual_effect_scene.instantiate() as VisualEffect
	vfx.setup(direction, _target.current_tile, _reaction.aoe, [_target], _reaction.visual_effect_targets_only, impact)
	GameState.current_level.add_child(vfx)
	
	_character.facing = _target.facing
	_character.animator.play_directional(_reaction.character_animation, _character.facing)
	_character.play_dialogue("taunt")
	_impact_time = _character.get_impact_time(_character.animator.current_animation)
	var damage_state := DamageState.new(_reaction, direction, impact, false, true)
	_target.set_state(damage_state)



func can_use(skill_state: SkillState, _actor: Character) -> bool:
	if _target is Ally != _character is Ally:
		if not skill_state is PushSkillState:
			if not skill_state.skill.status_effects.filter(func(x: StatusEffect) -> bool: return x.status == Combat.Status.HIT).is_empty():
				var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
				var valid_tiles: Array[Vector2i]
				
				for direction: Vector2i in directions:
					valid_tiles.append(_character.current_tile + direction)
				
				if _target.current_tile in valid_tiles and (_target is Ally) != (_character is Ally):
					var direction: Vector2i = _target.current_tile - _character.current_tile
					if is_equal_approx(Vector2(direction).dot(_target.facing), 1):
						return true
	return false

class_name CheapShotReactionState
extends ReactionState

var _tracking_cam: TrackingCamera

func enter() -> void:
	super.enter()
	_tracking_cam = (_character.get_viewport().get_camera_2d() as TrackingCamera)
	_tracking_cam.follow(_character)


func update(delta: float) -> State:
	if _tracking_cam.in_position and not _reacted:
		_react()
	elif _reacted and PhaseData.Event.IMPACT in _reaction_data.events and not _character.animator.is_playing():
		return CharacterIdleState.new()
	return super.update(delta)


func _react() -> void:
	super._react()
	var direction: Vector2i = _target.current_tile - _character.current_tile
	_character.facing = _target.facing
	_character.animator.play_directional(_reaction.character_animation, _character.facing)
	_impact_time = _character.get_impact_time(_character.animator.current_animation)
	var damage_state := DamageState.new(_reaction, direction, _reaction_data)
	_reaction_data.damage_states.append(damage_state)
	_reaction_data.targets.append(_target)


func can_use(skill: Skill, _actor: Character) -> bool:
	if _target is Ally != _character is Ally:
		if not skill.status_effects.filter(func(x: StatusEffect) -> bool: return x.status == Combat.Status.HIT).is_empty():
			var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			var valid_tiles: Array[Vector2i]
			
			for direction: Vector2i in directions:
				valid_tiles.append(_character.current_tile + direction)
			
			if _target.current_tile in valid_tiles and (_target is Ally) != (_character is Ally):
				var direction: Vector2i = _character.current_tile - _target.current_tile
				if is_equal_approx(Vector2(direction).dot(_target.facing), -1):
					return true
	return false

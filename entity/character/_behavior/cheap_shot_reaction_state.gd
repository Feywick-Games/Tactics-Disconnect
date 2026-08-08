class_name CheapShotReactionState
extends ReactionState

#var _tracking_cam: TrackingCamera
var _target_damage_state: DamageState
var _hit_delivered: bool

#func enter() -> void:
	#super.enter()
	#_tracking_cam = (_character.get_viewport().get_camera_2d() as TrackingCamera)
	#_tracking_cam.follow(_character)


func update(delta: float) -> State:
	if is_instance_valid(_target):
		if _target.state_machine.current_state is CharacterIdleState and not _hit_delivered and _reacted:
			_target.set_state(_target_damage_state)
			_hit_delivered = true
		elif _impact_emitted and not _target.state_machine.current_state is CharacterIdleState:
			return CharacterIdleState.new()
	else:
		return CharacterIdleState.new()
	if not _hit_delivered:
		_time_in_state = 0
	return super.update(delta)


func _react() -> void:
	super._react()
	var direction: Vector2i = _target.current_tile - _character.current_tile
	_character.facing = _target.facing
	_character.animator.play_directional(_reaction.character_animation, _character.facing)
	_impact_time = _character.get_impact_time(_character.animator.current_animation)
	_target_damage_state = DamageState.new(_reaction, direction, impact)


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

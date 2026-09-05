class_name GetBehindMeReactionState
extends ReactionState

var _moving := false
var _tile_path : Array[Vector2i]
var _target_tile_path: Array[Vector2i]
var _stolen_damage_state: DamageState


func update(_delta: float) -> State:
	if _reacted and not _moving and not _character.is_dialogue_playing():
		return _stolen_damage_state
	if not _qte_pending and _success:
		if not _reacted and not _moving:
			_react()
			
		if not is_instance_valid(_target):
			return CharacterIdleState.new()
	elif not _qte_pending:
		return CharacterIdleState.new()
	return


func physics_update(delta : float) -> State:
	if _moving:
		if not _tile_path.is_empty():
			_tile_path = _character.process_movement(delta, _tile_path, _character.move_animation)
		if not _target_tile_path.is_empty():
			_target_tile_path = _target.process_movement(delta, _target_tile_path, _character.move_animation)
		if _tile_path.is_empty() and _target_tile_path.is_empty():
			_moving = false
			_character.play_dialogue("knock_out")
			_target.facing = _character.facing
			_target.animator.play_directional("idle", _character.facing)
	return


func _react() -> void:
	super._react()
	_character.request_skill_text(_reaction.name)
	_character.show_health_bar(true)
	_target.show_health_bar(false)
	_character.facing = _target.facing
	_moving = true
	_stolen_damage_state = _target.state_machine.current_state
	_tile_path = [_target.current_tile]
	_target_tile_path = [_character.current_tile]
	_target.clear_expired_statuses()


func can_use(skill_state: SkillState, _actor: Character) -> bool:
	if _target is Ally == _character is Ally and _target.facing == _character.facing \
	and _target.current_tile == _character.current_tile + _character.facing:
		if not skill_state is PushSkillState:
			if not skill_state.skill.status_effects.filter(func(x: StatusEffect) -> bool: return x.status == Combat.Status.HIT).is_empty():
				var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
				var valid_tiles: Array[Vector2i]
				
				for direction: Vector2i in directions:
					valid_tiles.append(_character.current_tile + direction)
				
				if _target.current_tile in valid_tiles:
					var direction: Vector2i = _target.current_tile - _character.current_tile
					if is_equal_approx(Vector2(direction).dot(_target.facing), 1):
						return true
	return false

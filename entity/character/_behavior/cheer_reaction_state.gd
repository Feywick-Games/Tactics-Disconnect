class_name CheerReactionState
extends ReactionState

func update(_delta: float) -> State:
	if not _character.animator.is_playing() and _reacted:
		return CharacterIdleState.new()
	elif not _qte_pending and not _success:
		return CharacterIdleState.new()
	if _success and not _reacted:
		_reacted = true
		_react()
	return


func _react() -> void:
	super._react()
	_character.animator.play_directional("idle", _character.facing)
	_character.request_skill_text(_reaction.name)
	_character.play_dialogue("cheer")


func can_use(_skill_state: SkillState, actor: Character) -> bool:
	if actor is Ally == _character is Ally:
		var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		var valid_tiles: Array[Vector2i]
		for direction in directions:
			var tile: Vector2i = _character.current_tile + direction
			valid_tiles.append(tile)
		
		if actor.current_tile in valid_tiles:
			if actor.facing == _character.facing:
				return true
	return false 

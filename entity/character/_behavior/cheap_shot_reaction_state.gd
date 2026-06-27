class_name CheapShotReactionState
extends ReactionState

signal processed

var _animation_complete := false


func enter() -> void:
	super.enter()
	var direction: Vector2i = _target.current_tile - _character.current_tile
	_character.animator.play_directional(_reaction.character_animation)
	_character.animator.animation_finished.connect(_on_animation_finished)
	var damage_state := DamageState.new(_reaction, direction, INF, _character.target_hit, 1, false)
	_target.state_requested.emit(damage_state)
	if not _reaction.is_animated:
		_character.notify_impact()


func update(delta: float) -> State:
	
	if _animation_complete:
		_exiting = true
	
	
	return super.update(delta)


func _on_animation_finished(_anim: String) -> void:
	_animation_complete = true


func can_use() -> bool:
	if not _target.status.filter(func(x: StatusEffect) -> bool: return x.status == Combat.Status.HIT).is_empty():
		var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		var valid_tiles: Array[Vector2i] = [_character.current_tile]
		
		for direction: Vector2i in directions:
			valid_tiles.append(_character.current_tile + direction)
		
		if _target.current_tile in valid_tiles and (_target is Ally) != (_character is Ally):
			var direction: Vector2i = _target.current_tile - _character.current_tile
			
			if direction == _target.facing and (direction == _character.facing or _character.facing == Vector2i.ZERO):
				return true
	
	return false


func exit() -> void:
	processed.emit()

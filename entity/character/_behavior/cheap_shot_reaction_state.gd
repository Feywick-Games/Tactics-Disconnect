class_name CheapShotReactionState
extends ReactionState

var _reacted := false
var _tracking_cam: TrackingCamera

func enter() -> void:
	_tracking_cam = (_character.get_viewport().get_camera_2d() as TrackingCamera)
	_tracking_cam.follow(_character)


func update(delta: float) -> State:
	if _tracking_cam.in_position and not _reacted:
		_react()
	elif _reacted and _target.state_machine.current_state is CharacterIdleState:
		return CharacterIdleState.new()
	return super.update(delta)


func _react() -> void:
	_reacted = true
	var direction: Vector2i = _target.current_tile - _character.current_tile
	_character.facing = _target.facing
	_character.animator.play_directional(_reaction.character_animation, _character.facing)
	var damage_state := DamageState.new(_reaction, direction, _character.target_hit, false)
	_target.set_state(damage_state)
	_character.notify_impact()


func can_use() -> bool:
	if not _target.status.filter(func(x: StatusEffect) -> bool: return x.status == Combat.Status.HIT).is_empty():
		var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		var valid_tiles: Array[Vector2i]
		
		for direction: Vector2i in directions:
			valid_tiles.append(_character.current_tile + direction)
		
		if _target.current_tile in valid_tiles and (_target is Ally) != (_character is Ally):
			var direction: Vector2i = _character.current_tile - _target.current_tile
			if is_equal_approx(Vector2(direction).dot(_target.facing), -1):
				return true
	return false

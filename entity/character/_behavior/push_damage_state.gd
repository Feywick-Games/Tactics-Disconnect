class_name PushDamageState
extends DamageState

signal collided

var _tile_path: Array[Vector2i]
var _has_collided := false

func _init(tile_path: Array[Vector2i],
skill: Skill, direction: Vector2, impact_signal: Signal) -> void:
	super._init(skill, direction, impact_signal)
	_tile_path = tile_path


func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.animator.play_directional("idle", _direction * -1)
	_character.facing = _direction * -1


func update(delta: float) -> State:
	if _damage_taken:
		if not _tile_path.is_empty():
			_tile_path = _character.process_movement(delta, _tile_path, "", true)
		elif not _has_collided:
			_has_collided = true
			GameState.current_level.grid.update_unit_registry(_character.current_tile, _character)
			collided.emit()
	
	var parent_state: State = super.update(delta)
	if parent_state:
		if _tile_path.is_empty() and _has_collided:
			return parent_state

	return

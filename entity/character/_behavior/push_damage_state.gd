class_name PushDamageState
extends DamageState

signal collided

var _tile_path: Array[Vector2i]
var _has_collided := false

func _init(tile_path: Array[Vector2i],
skill: Skill, direction: Vector2, impact_signal: Signal, multiplier: float = 1) -> void:
	super._init(skill, direction, impact_signal, multiplier)
	_tile_path = tile_path


func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.show_health_bar(true)
	_character.animator.play_directional("idle", _direction * -1)
	_character.facing = _direction * -1

func update(delta: float) -> State:
	var parent_state: State = super.update(delta)
	if parent_state:
		if _tile_path.is_empty():
			return parent_state
	
	if _damage_taken:
		if not _tile_path.is_empty():
			_tile_path = _character.process_movement(delta, _tile_path, "")
		elif not _has_collided:
			_has_collided = true
			GameState.current_level.grid.update_unit_registry(_character.current_tile, _character)
			collided.emit()
	return

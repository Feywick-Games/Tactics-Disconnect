class_name PushDamageState
extends DamageState

var _tile_path: Array[Vector2i]
var _is_pushing := false


func _init(tile_path: Array[Vector2i],
skill: Skill, direction: Vector2, turn_data: PhaseData, multiplier: float = 1) -> void:
	super._init(skill, direction, turn_data, multiplier)
	_tile_path = tile_path


func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.health_bar.show()
	_character.animator.play_directional("idle", _direction * -1)
	_character.facing = _direction * -1
	_is_pushing = true


func update(delta: float) -> State:
	var parent_state: State = super.update(delta)
	if parent_state:
		return parent_state
	
	if _is_pushing:
		if not _tile_path.is_empty():
			_tile_path = _character.process_movement(delta, _tile_path, "")
		else:
			GameState.current_level.grid.update_unit_registry(_character.current_tile, _character)
			_damage_data.events.append(PhaseData.Event.COLLIDED)
			_is_pushing = false
	return

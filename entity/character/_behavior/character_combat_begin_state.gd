class_name CharacterCombatBeginState
extends State

const SNAP_DISTANCE: float = 1

var _target_position: Vector2
var _character: Character
var _waiting := true

func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.current_tile = GameState.current_level.grid.get_nearest_available_tile(_character.global_position)
	GameState.current_level.grid.update_unit_registry(_character.current_tile, _character)
	_target_position = GameState.current_level.tile_to_world(_character.current_tile)
	_character.start_encounter()
	_character.animator.animation_finished.connect(_on_spawn_animation_finished)


func _on_spawn_animation_finished(_anim: String) -> void:
	_waiting = false


func update(_delta: float) -> State:
	if not _waiting:
		_character.global_position = GameState.current_level.tile_to_world(_character.current_tile)
		return CharacterIdleState.new()
	
	return


func exit() -> void:
	_character.spawn_completed.emit()

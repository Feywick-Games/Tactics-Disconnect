class_name PushDamageState
extends DamageState

signal collided

var _tile_path: Array[Vector2i]
var _o_target: Character
var _is_pushing := false


func _init(tile_path: Array[Vector2i], o_target: Character, 
skill: Skill, direction: Vector2, hit_signal: Signal, multiplier: float = 1, request_reaction:=true) -> void:
	super._init(skill, direction, hit_signal, multiplier, request_reaction)
	_tile_path = tile_path
	_o_target = o_target


func enter() -> void:
	super.enter()
	if _o_target:
		var damage_state := DamageState.new(_skill, _direction, collided, _damage_multiplier)
		_o_target.set_state(damage_state)


func _on_hit() -> void:
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
			collided.emit.call_deferred()
			_hit = true
			_is_pushing = false
	return

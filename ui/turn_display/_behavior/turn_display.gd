class_name TurnDisplay
extends BoxContainer

var _units: Array[Character]
var _current_unit_idx: int = -1
var _current_unit: Character:
	get:
		return _units[_current_unit_idx]
var _turn_portraits: Array[TurnPortrait]
var _battle_started := false
var _turn_pending := false
var _is_first_turn := false

func _ready() -> void:
	EventBus.skills_selected.connect(_on_first_skills_selected)
	EventBus.cam_position_reached.connect(_on_cam_position_reached)
	EventBus.unit_spawned.connect(_add_unit)
	hide()
	# load allied units
	var combatants: Array = get_tree().get_nodes_in_group("ally")
	for unit: Character in combatants:
		_add_unit(unit)


func _on_encounter_ended() -> void:
	hide()
	_battle_started = false
	for child in get_children():
		queue_free()
	_units.clear()
	_turn_pending = false
	EventBus.encounter_ended.emit()


func _start_turn() -> void:
	var enemies_remaining := false
	var allies_remaining := false
	for unit in _units:
		if unit is Enemy:
			enemies_remaining = true
			break
	
	for unit in _units:
		if unit is Ally:
			allies_remaining = true
			break
	
	if not enemies_remaining:
		_on_encounter_ended()
		return
	elif not allies_remaining:
		get_tree().reload_current_scene()
		return
	
	_update_turn_portraits()
	
	if _current_unit_idx != -1:
		_turn_portraits[_current_unit_idx].reset_portrait()
		move_child(_turn_portraits[_current_unit_idx], -1)
	_increment_unit_index()
	var turn_portait := _turn_portraits[_current_unit_idx]
	turn_portait.display_full_portrait()
	EventBus.cam_follow_requested.emit(_current_unit, Vector2.ZERO)
	_turn_pending = true


func _update_turn_portraits() -> void:
	for child in get_children():
		remove_child(child)
	
	for i in range(max(_current_unit_idx,0), len(_turn_portraits)):
		add_child(_turn_portraits[i])
	for i in range(max(_current_unit_idx,0)):
		add_child(_turn_portraits[i])
	
	for _turn_portrait: TurnPortrait in _turn_portraits:
		_turn_portrait.update()


func _process(_delta: float) -> void:
	if visible:
		if not _battle_started and not _units.is_empty() and GameState.current_level.map_complete:
			var units_waiting := false
			for unit in _units:
				if not unit.ready_for_battle:
					units_waiting = true
					break
			if not units_waiting:
				_battle_started = true
				
			if _battle_started:
				_start_turn()
				
				
func _on_cam_position_reached() -> void:
	if _turn_pending:
		_turn_pending = false
		EventBus.turn_started.emit(_current_unit)


func _on_first_skills_selected() -> void:
	EventBus.skills_selected.disconnect(_on_first_skills_selected)
	_turn_pending = false
	_is_first_turn = true
	if not visible:
		show()
	
	_current_unit_idx = -1
	EventBus.spawns_processed.connect(_start_turn)
	_start_turn()


func _add_unit(unit: Character) -> void:
	_units.append(unit)
	unit.died.connect(_on_unit_died.bind(unit))
	var turn_portrait: TurnPortrait = unit.turn_portrait_scene.instantiate()
	turn_portrait.set_up(unit)
	_turn_portraits.append(turn_portrait)
	_update_turn_portraits()


func _increment_unit_index(val: int = 1) -> void:
	if _current_unit_idx + val < len(_units):
		_current_unit_idx += val
	else:
		_current_unit_idx = -1 + val


func _on_unit_died(unit: Character) -> void:
	if not _units.is_empty():
		var idx: int = _units.find(unit)
		_units.remove_at(idx)
		var child: Node = _turn_portraits[idx]
		_turn_portraits.remove_at(idx)
		child.queue_free()
		
		if idx <= _current_unit_idx:
			_increment_unit_index()

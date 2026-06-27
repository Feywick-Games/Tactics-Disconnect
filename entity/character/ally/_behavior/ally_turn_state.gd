class_name AllyTurnState
extends TurnState

const TIME_TILL_UPDATE_RETICLE : float = .1

var _ally: Ally
var force_redraw := false
var _time_since_update_reticle : float = 0

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_ally.attack_state = Combat.AttackState.BASIC
	_movement_astar = _ally.create_range_astar(_movement_range, _ally.movement_range)
	_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
	EventBus.timed_out.connect(_on_timed_out)


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	
	var _current_state: State = super.update(delta)
	if _current_state:
		return _current_state
	
	var hover_tile: Vector2i = _highlighted_tile
	var reticle_dir : Vector2i = Vector2i(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	
	_time_since_update_reticle += delta
	
	if reticle_dir != Vector2i.ZERO and _time_since_update_reticle > TIME_TILL_UPDATE_RETICLE:
		_time_since_update_reticle = 0
		hover_tile = hover_tile + reticle_dir
		
	if Input.is_action_pressed("move") and not acted:
		var n_vec : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if _ally.current_tile + Vector2i(n_vec) in _movement_range.range_tiles:
			_tile_path = [_ally.current_tile + Vector2i(n_vec)]
	elif acted and _highlighted_tile != hover_tile and \
	(hover_tile in _attack_range.range_tiles or hover_tile in _interactable_range):
		_highlight_targets(_highlighted_tile, false)
		_highlight_targets(hover_tile)
		_highlighted_tile = hover_tile
	
	if Input.is_action_just_pressed("guard"):
			_ally.get_viewport().set_input_as_handled()
			_ally.facing = Vector2i.ZERO
			#TODO add exit animation where they align themselves on the tile 
			_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile)
			_ally.end_turn()
			_current_state = CharacterCombatIdleState.new()
	elif Input.is_action_just_pressed("cancel"):
		if acted and not interacted:
			acted = false
			EventBus.tiles_highlighted.emit(
				[] as Array[Vector2i], [] as Array[StatusEffect], 0, Vector2i.ZERO, true
			)
			_movement_range = _starting_movement_range
			force_redraw = true
	elif Input.is_action_just_pressed("special"):
		if _ally.special.is_ready() and _ally.attack_state == Combat.AttackState.BASIC:
			_ally.attack_state = Combat.AttackState.SPECIAL
		elif _ally.attack_state == Combat.AttackState.SPECIAL:
			_ally.attack_state = Combat.AttackState.BASIC
		elif _ally.attack_state == Combat.AttackState.ITEM:
			_ally.attack_state = Combat.AttackState.ITEM
		force_redraw = true
			
			
		if acted:
			EventBus.tiles_highlighted.emit(
				[] as Array[Vector2i], [] as Array[StatusEffect], 0, Vector2i.ZERO, true
			)
		force_redraw = true
	elif Input.is_action_just_pressed("accept") and not acted:
		acted = true
		force_redraw = true
		_movement_range = RangeStruct.new()
		_highlighted_tile = _ally.current_tile
	elif  Input.is_action_just_pressed("accept") and acted and _highlighted_tile != _ally.current_tile:
		_current_state = _ally.process_action(_highlighted_tile, _attack_range, self)
		if _current_state:
			force_redraw = true
		if interacted:
			_movement_range = RangeStruct.new()
			_interactable_range = GameState.current_level.get_interactable_tiles(_movement_range.range_tiles)
	

	return _current_state


func physics_update(delta: float) -> State:
	var current_tile: Vector2i = _ally.current_tile
	super.physics_update(delta)
	if current_tile != _ally.current_tile or force_redraw:
		force_redraw = false
		_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
		if acted:
			GameState.current_level.select_tile(_highlighted_tile, true)
		if interacted:
			_highlight_targets(_highlighted_tile)
	return

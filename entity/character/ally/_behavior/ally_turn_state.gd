class_name AllyTurnState
extends TurnState

const TIME_TILL_UPDATE_RETICLE : float = .2
const MOVMENT_BUFFER_TIME: float = .1

var _ally: Ally
var force_redraw := false
var _time_since_update_reticle : float = 0
var _input_buffered: Callable
var _skill_select_opened := false

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_ally.attack_state = Combat.AttackState.BASIC
	_movement_astar = _ally.create_range_astar(_movement_range, _ally.movement_range)
	_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
	EventBus.timed_out.connect(_on_timed_out)
	EventBus.skills_selected.connect(_on_skills_selected)


func _on_skills_selected() -> void:
	_skill_select_opened = false


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	
	var current_state: State = super.update(delta)
	if current_state:
		return current_state
	
	if not _skill_select_opened:
		_time_since_update_reticle += delta
		
		if Input.is_action_pressed("move") and _time_since_update_reticle > TIME_TILL_UPDATE_RETICLE:
			_time_since_update_reticle = 0
			var input_vec := Vector2i(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
			print(input_vec)
			_input_buffered = _on_movememen_input.bind(input_vec)
		if Input.is_action_just_pressed("guard"):
			_input_buffered = _on_guard_pressed
		elif Input.is_action_just_pressed("cancel"):
			_input_buffered = _on_cancel_pressed
		elif Input.is_action_just_pressed("special") and _ally.special:
			_input_buffered = _on_special_pressed
		elif Input.is_action_just_pressed("accept"):
			_input_buffered = _on_accept_pressed
		elif Input.is_action_just_pressed("skill_select"):
			_input_buffered = _on_skill_select_pressed
		
		if not _input_buffered.is_null() and not _moving:
			current_state = _input_buffered.call()
			_input_buffered = Callable()
			return current_state
	
	return current_state
	
	
func _on_skill_select_pressed() -> void:
	if GameState.is_skill_select_ready:
		_skill_select_opened = true
		EventBus.skill_select_opened.emit()
	
	
func _on_movememen_input(input_vec: Vector2i) -> State:
	var hover_tile: Vector2i = _highlighted_tile
	
	if acted:
		if input_vec != Vector2i.ZERO:
			# facing will favor not rotating when angle is 45 degrees
			hover_tile = _attack_range.get_neighbor(hover_tile, input_vec)
			
			var face_vec: Vector2 = hover_tile - _ally.current_tile
			
			if not is_equal_approx(abs(face_vec.x), abs(face_vec.y)):
				face_vec = Vector2i(VectorF.snap_direction(face_vec.normalized()))
				_ally.facing = face_vec
				_ally.animator.play_directional("idle", _ally.facing)
			
		if _highlighted_tile != hover_tile and \
		(hover_tile in _attack_range.range_tiles or hover_tile in _interactable_range):
			_highlight_targets(hover_tile)
			_highlighted_tile = hover_tile
	else:
		if _ally.current_tile + Vector2i(input_vec) in _movement_range.range_tiles:
			_tile_path = [_ally.current_tile + Vector2i(input_vec)]
			_moving = true
		_ally.facing = input_vec
		_ally.animator.play_directional("idle", _ally.facing)
	
	return

func _on_guard_pressed() -> State:
	_ally.get_viewport().set_input_as_handled()
	_ally.facing = Vector2i.ZERO
	#TODO add exit animation where they align themselves on the tile 
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile)
	_ally.end_turn()
	return CharacterCombatIdleState.new()


func _on_cancel_pressed() -> State:
	if acted and not interacted:
		acted = false
		EventBus.tiles_highlighted.emit(
			[] as Array[Vector2i], [] as Array[StatusEffect], 0, Vector2i.ZERO, true
		)
		_movement_range = _starting_movement_range
		force_redraw = true
	return


func _on_special_pressed() -> State:
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
	
	return


func _on_accept_pressed() -> State:
	var current_state: State
	if not acted:
		acted = true
		force_redraw = true
		_movement_range = RangeStruct.new()
		_highlighted_tile = _ally.current_tile + _ally.facing
	elif  Input.is_action_just_pressed("accept") and acted:
		current_state = _ally.process_action(_highlighted_tile, _attack_range, self)
		if current_state:
			force_redraw = true
		if interacted:
			_movement_range = RangeStruct.new()
			_interactable_range = GameState.current_level.get_interactable_tiles(_movement_range.range_tiles)
	
	return current_state

func physics_update(delta: float) -> State:
	var current_tile: Vector2i = _ally.current_tile
	super.physics_update(delta)
	if current_tile != _ally.current_tile or force_redraw:
		force_redraw = false
		_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
		if acted or interacted:
			_highlight_targets(_highlighted_tile)
	return

class_name AllyTurnState
extends TurnState

const TIME_TILL_UPDATE_RETICLE : float = .2

var _ally: Ally
var force_redraw := false
var _time_since_update_reticle : float = 0
var _input_buffered: Callable
var _skill_select_opened := false
var _wait_range: RangeStruct
var waited := false

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_ally.health_bar.show()
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_ally.attack_state = Combat.AttackState.BASIC
	_movement_astar = _ally.create_range_astar(_movement_range, _ally.movement_range)
	_attack_range = _ally.update_ranges(_movement_range)


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	
	var current_state: State = super.update(delta)
	if current_state:
		return current_state
	
	if not _skill_select_opened:
		_time_since_update_reticle += delta
		
		if Input.is_action_pressed("move") and _time_since_update_reticle > TIME_TILL_UPDATE_RETICLE * 1.25:
			_time_since_update_reticle = 0
			var input_vec := Vector2i(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
			_input_buffered = _on_movememen_input.bind(input_vec)
		if Input.is_action_just_pressed("guard"):
			_input_buffered = _on_guard_pressed
		elif Input.is_action_just_pressed("cancel"):
			_input_buffered = _on_cancel_pressed
		elif Input.is_action_just_pressed("special") and _ally.special:
			_input_buffered = _on_special_pressed
		elif Input.is_action_just_pressed("accept"):
			_input_buffered = _on_accept_pressed
		
		if not _input_buffered.is_null() and not _moving:
			current_state = _input_buffered.call()
			_input_buffered = Callable()
			return current_state
	
	return current_state



func _on_movememen_input(input_vec: Vector2i) -> State:
	var hover_tile: Vector2i = _highlighted_tile
	
	if acted or waited:
		if input_vec != Vector2i.ZERO:
			# facing will favor not rotating when angle is 45 degrees
			if acted:
				hover_tile = _attack_range.get_neighbor(hover_tile, input_vec) 
			else:
				hover_tile = _wait_range.get_neighbor(hover_tile, input_vec)
			
			var face_vec: Vector2 = hover_tile - _ally.current_tile
			
			if not is_equal_approx(abs(face_vec.x), abs(face_vec.y)):
				face_vec = Vector2i(VectorF.snap_direction(face_vec.normalized()))
				_ally.facing = face_vec
				_ally.animator.play_directional("idle", _ally.facing)
			
		if _highlighted_tile != hover_tile:
			if acted:
				_highlight_targets(hover_tile)
			elif waited:
				GameState.current_level.reticle.select_tile(_highlighted_tile, false)
				GameState.current_level.reticle.select_tile(hover_tile, true)
			
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
	waited = true
	#TODO add exit animation where they align themselves on the tile 
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile)
	_wait_range = RangeStruct.new()
	_wait_range.range_tiles = [
		_ally.current_tile + Vector2i.LEFT, _ally.current_tile + Vector2i.RIGHT
		, _ally.current_tile + Vector2i.UP, _ally.current_tile + Vector2i.DOWN
	]
	
	GameState.current_level.reset_map()
	
	for tile : Vector2i in _wait_range.range_tiles:
		if tile - _ally.current_tile == Vector2i.RIGHT:
			GameState.current_level.reticle.draw_range([tile], Global.RETICLE_FACING_RIGHT)
		elif tile - _ally.current_tile == Vector2i.DOWN:
			GameState.current_level.reticle.draw_range([tile], Global.RETICLE_FACING_DOWN)
		elif tile - _ally.current_tile == Vector2i.LEFT:
			GameState.current_level.reticle.draw_range([tile], Global.RETICLE_FACING_LEFT)
		else:
			GameState.current_level.reticle.draw_range([tile], Global.RETICLE_FACING_UP)

	_highlighted_tile = _ally.current_tile + _ally.facing
	GameState.current_level.reticle.select_tile(_highlighted_tile)
	
	return



func _on_cancel_pressed() -> State:
	if acted and not interacted:
		acted = false
		_character.tiles_highlighted.emit(
			[] as Array[Vector2i], [] as Array[StatusEffect], Vector2i.ZERO, true
		)
		_movement_range = _starting_movement_range
		force_redraw = true
	elif waited:
		waited = false
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
		
	if acted:
		_character.tiles_highlighted.emit(
			[] as Array[Vector2i], [] as Array[StatusEffect], Vector2i.ZERO, true
		)
	force_redraw = true
	
	return


func _on_accept_pressed() -> State:
	if waited:
		end_turn()
	elif acted:
		var selected: bool = _ally.select_action(_highlighted_tile, _attack_range, self)
		if selected:
			force_redraw = true
			end_turn()
	else:
		acted = true
		force_redraw = true
		_movement_range = RangeStruct.new()
		_highlighted_tile = _ally.current_tile + _ally.facing
	return


func physics_update(delta: float) -> State:
	var current_tile: Vector2i = _ally.current_tile
	super.physics_update(delta)
	if current_tile != _ally.current_tile or force_redraw:
		force_redraw = false
		_attack_range = _ally.update_ranges(_movement_range)
		if acted or interacted:
			_highlight_targets(_highlighted_tile)
	return


func exit() -> void:
	super.exit()
	_ally.health_bar.hide()

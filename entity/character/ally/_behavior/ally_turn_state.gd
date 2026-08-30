class_name AllyTurnState
extends TurnState

const TIME_TILL_UPDATE_RETICLE : float = .2

var _ally: Ally
var force_redraw := false
var _time_since_update_reticle : float = 0
var _input_buffered: Callable
var _wait_range: RangeStruct
var _camera_leader_speed: float = 120
var _camera_leader: Node2D
var _tracking_cam: TrackingCamera
var waited := false

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_start_tile = _ally.current_tile
	_attack_range = _ally.update_ranges(_movement_range)
	_tracking_cam = _character.get_viewport().get_camera_2d()
	_camera_leader = Node2D.new()
	_character.add_child(_camera_leader)
	_tracking_cam.follow(_camera_leader)


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	
	var current_state: State = super.update(delta)
	if current_state:
		return current_state
	
	_time_since_update_reticle += delta
	
	if Input.is_action_pressed("move") and _time_since_update_reticle > TIME_TILL_UPDATE_RETICLE * 1.25:
		_time_since_update_reticle = 0
		var input_vec := Vector2i(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
		_input_buffered = _on_movement_input.bind(input_vec)
	if Input.is_action_just_pressed("guard"):
		_input_buffered = _on_guard_pressed
	elif Input.is_action_just_pressed("cancel"):
		_input_buffered = _on_cancel_pressed
	elif Input.is_action_just_pressed("special") and _ally.special:
		_input_buffered = _on_special_pressed
	elif Input.is_action_just_pressed("accept"):
		_input_buffered = _on_accept_pressed
	
	if Input.is_action_just_pressed("inspect"):
		_turn_data.force_show_health = true
	
	if Input.is_action_just_released("inspect") and not acted:
		_camera_leader.position = Vector2.ZERO
		_turn_data.force_show_health = false
		_input_buffered = Callable()
	
	if Input.is_action_pressed("inspect") and not acted:
		_camera_leader.position += Input.get_vector("move_left", "move_right", "move_up", "move_down") * _camera_leader_speed * delta
		_camera_leader.global_position = _camera_leader.global_position.clamp(_tracking_cam.bounds.position, _tracking_cam.bounds.end)
	
	elif not _input_buffered.is_null() and not _moving:
		current_state = _input_buffered.call()
		_input_buffered = Callable()
			
		return current_state
	
	return current_state



func _on_movement_input(input_vec: Vector2i) -> State:
	if not Input.is_action_pressed("inspect"):
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
					if acted:
						_ally.animator.play_directional("idle", _ally.facing)
					elif waited:
						_ally.animator.play_directional("move_idle", _ally.facing)
			if _highlighted_tile != hover_tile:
				if acted:
					_highlight_targets(hover_tile)
				elif waited:
					GameState.current_level.reticle.select_tile(_highlighted_tile, false)
					GameState.current_level.reticle.select_tile(hover_tile, true)
				
				_highlighted_tile = hover_tile
				if acted:
					_camera_leader.global_position = GameState.current_level.tile_to_world(_highlighted_tile).lerp(GameState.current_level.tile_to_world(_character.current_tile), .5)
		else:
			if _ally.current_tile + Vector2i(input_vec) in _movement_range.range_tiles:
				_tile_path = [_ally.current_tile + Vector2i(input_vec)]
				_moving = true
			_ally.facing = input_vec
			_ally.animator.play_directional("move_idle", _ally.facing)
	return


func _on_guard_pressed() -> State:
	_ally.get_viewport().set_input_as_handled()
	waited = true
	acted = false
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
	
	if _ally.animator.current_animation != "move_idle":
		_ally.animator.play_directional("move_idle", _ally.facing)
	
	return



func _on_cancel_pressed() -> State:
	if acted:
		acted = false
		_camera_leader.position = Vector2.ZERO
		_turn_data.active_skill_state = null
		_movement_range = _starting_movement_range
		force_redraw = true
		if _ally.animator.current_animation != "move_idle":
			_ally.animator.play_directional("move_idle", _ally.facing)
	elif waited:
		waited = false
		_movement_range = _starting_movement_range
		force_redraw = true
	return


func _on_special_pressed() -> State:
	_ally.active_skill = _ally.basic_skill if _ally.active_skill != _ally.basic_skill else _ally.special
	force_redraw = true
	return


func _on_accept_pressed() -> State:
	if waited:
		end_turn()
	elif acted:
		var next_state: State = _select_action(_highlighted_tile, _attack_range, self)
		return next_state 
	else:
		acted = true
		_character.animator.play_directional("idle", _character.facing)
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
		if acted:
			_highlight_targets(_highlighted_tile)
	return


func exit() -> void:
	if waited:
		_character.animator.play_directional("idle", _character.facing)
	super.exit()

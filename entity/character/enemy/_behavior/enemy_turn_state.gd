class_name EnemyTurnState
extends TurnState

const HIGHLIGHT_TIME: float = 2.5

var _enemy: Enemy
var _target: Character
var _full_attack_range := RangeStruct.new()
var _full_special_range := RangeStruct.new()
var _is_acting := false
var _time_highlight: float = 0
var _has_highlighted := false

class TargetPriority:
	var target:  Character
	var knock_out_likelihood: float
	var basic_skill_likelihood: float
	var distance: float
	var special_likelihood: float
	var rating: float
	
	func  _init(target_to_calc: Character) -> void:
		target = target_to_calc


func enter() -> void:
	super.enter()
	_enemy = state_machine.state_owner as Enemy
	_populate_attack_ranges()
	
	var units_on_field: Array[Node] = _enemy.get_tree().get_nodes_in_group("ally")
	units_on_field.shuffle()
	var target_list: Array[Ally]
	var all_allies: Array[Ally]
	
	for unit: Ally in units_on_field:
		if unit.current_tile in _full_attack_range.range_tiles or unit.current_tile in _full_special_range.range_tiles:
			target_list.append(unit)
		all_allies.append(unit)
	
	_target = _pick_target(target_list, all_allies)
	if _target:
		var target_tile: Vector2i = _pick_tile()
		if target_tile == _enemy.current_tile:
			# don't draw a movement if it's just going to flicker on
			_movement_range = RangeStruct.new()
		_attack_range = _enemy.update_ranges(_movement_range)
		if _movement_astar:
			_tile_path = _movement_astar.get_id_path(_enemy.current_tile, target_tile)


func update(delta: float) -> State:
	if not _exiting and _tile_path.is_empty() and _is_acting:
		if _time_highlight >= HIGHLIGHT_TIME:
			var next_state: State = _select_action(_target.current_tile, _attack_range, self)
			return next_state
		else:
			_wait(delta)
	elif _exiting or (_tile_path.is_empty() and not _is_acting):
		_character.animator.play_directional("idle", _character.facing)
		_enemy.end_turn()
		return CharacterIdleState.new()
	return


func physics_update(delta: float) -> State:
	var current_tile := _enemy.current_tile
	super.physics_update(delta)
	if current_tile != _enemy.current_tile and not _has_highlighted:
		_attack_range = _enemy.update_ranges(_movement_range)
	return


func _populate_attack_ranges() -> void:
	for tile: Vector2i in _movement_range.range_tiles:
		var valid_tiles := GameState.current_level.grid.request_range(tile, _enemy.basic_skill.min_range, _enemy.basic_skill.max_range, _enemy.basic_skill.range_shape, true, _enemy.basic_skill.direct)
		_full_attack_range.absorb(valid_tiles)
		
	if _enemy.special:
		for tile: Vector2i in _movement_range.range_tiles:
			var skill_range := GameState.current_level.grid.request_range(tile, 
				_enemy.special.min_range, _enemy.special.max_range, _enemy.special.range_shape, 
				true, _enemy.special.direct
			)
			var units: Array[Character]
			
			for skill_tile: Vector2i in skill_range.range_tiles:
				var unit: Character = GameState.current_level.grid.get_unit_from_tile(skill_tile)
				if unit and unit != self and not unit in units:
					units.append(unit)
			
			for unit: Character in units:
				var skill_state: SkillState = _enemy.special.state.new(_enemy, _enemy.special, unit.current_tile)
				if skill_state.can_use(skill_range) == Global.SkillErrorCode.OK:
					_full_special_range.range_tiles.append(unit.current_tile)


func _pick_target(target_list: Array[Ally], all_allys: Array[Ally]) -> Ally:
	var current_target: Ally
	
	var target_priorities: Array[TargetPriority]
	if target_list.is_empty():
		for target in all_allys:
			var target_priority := TargetPriority.new(target)
			target_priorities.append(target_priority)
			target_priority.distance = GameState.current_level.grid.get_tile_distance(_enemy.current_tile, target.current_tile, true)
			var true_distance: int = GameState.current_level.grid.get_tile_distance(_enemy.current_tile, target.current_tile)
			if true_distance > target_priority.distance or true_distance == -1:
				if true_distance > 0:
					target_priority.distance = min(true_distance, target_priority.distance + 1)
				else:
					target_priority.distance = target_priority.distance + 1
			
			if target_priority.distance < 0:
				target_priority.distance = -100
				continue
			target_priority.distance = 1 - (target_priority.distance/float(_enemy.movement_range))
			target_priority.distance *= Enemy.DISTANCE_PRIORITY
			target_priority.knock_out_likelihood = 1 if target.health - _enemy.basic_skill.get_hit_damage() < 0 else 0
		_is_acting = false
	else:
		for target in target_list:
			# disqualify enemies not in the skill range
			var target_priority := TargetPriority.new(target)
			target_priorities.append(target_priority)
			target_priority.distance = GameState.current_level.grid.get_tile_distance(_enemy.current_tile, target.current_tile)
			var enemy_max_skill_range: float = _enemy.basic_skill.max_range
			if _enemy.special:
				enemy_max_skill_range = max(enemy_max_skill_range, _enemy.special.max_range)
			enemy_max_skill_range += _enemy.movement_range 
			target_priority.distance = 1 - (target_priority.distance/float(enemy_max_skill_range))
			target_priority.distance *= Enemy.DISTANCE_PRIORITY
			target_priority.knock_out_likelihood = 1 if target.health - _enemy.basic_skill.get_hit_damage() < 0 else 0
			target_priority.knock_out_likelihood *= _enemy.knock_out_priority
			if target.current_tile in _full_attack_range.range_tiles: 
				var skill_likelihoods: Array[float] = []
				for tile in _movement_range.range_tiles:
					var basic_skill_state: SkillState = (_character.basic_skill.state.new(_character, _character.basic_skill, target.current_tile, tile) as SkillState)	
					skill_likelihoods.append(basic_skill_state.calc_skill_likelihood(_turn_history))
				target_priority.basic_skill_likelihood = skill_likelihoods.max()
				target_priority.basic_skill_likelihood *= _enemy.basic_skill_priority
			if _enemy.special and target.current_tile in _full_special_range.range_tiles:
				var skill_likelihoods: Array[float] = []
				for tile in _movement_range.range_tiles:
					var special_skill_state: SkillState = (_character.special.state.new(_character, _character.special, target.current_tile, tile) as SkillState)	
					skill_likelihoods.append(special_skill_state.calc_skill_likelihood(_turn_history))
				target_priority.special_likelihood = skill_likelihoods.max()
				target_priority.special_likelihood *= _enemy.special_priority
		_is_acting = true
 	
	for target_priority: TargetPriority in target_priorities:
		target_priority.rating += target_priority.distance
		target_priority.rating += target_priority.knock_out_likelihood
		target_priority.rating += max(target_priority.special_likelihood, target_priority.basic_skill_likelihood)
	
	var max_rating: float = -INF
	for target_priority: TargetPriority in target_priorities:
		if target_priority.rating > max_rating:
			max_rating = target_priority.rating
			current_target = target_priority.target
			if _is_acting:
				_enemy.active_skill = _enemy.basic_skill if target_priority.basic_skill_likelihood > target_priority.special_likelihood else _enemy.special
	
	return current_target


func _pick_tile() -> Vector2i:
	var desired_tile: Vector2i = _start_tile
	
	if not _is_acting:
		# dont worry about desired distance if you are literally out of range
		var start_distance: int = GameState.current_level.grid.get_tile_distance(_start_tile, _target.current_tile, true)
		var start_dist_actual: int = GameState.current_level.grid.get_tile_distance(_start_tile, _target.current_tile)
		# add marginal favorability to direct approach
		if start_dist_actual > start_distance or start_dist_actual == -1:
			if start_dist_actual > 0:
				start_distance = min(start_distance + 1, start_dist_actual)
			else:
				start_distance = start_distance + 1
		var min_distance: int = start_distance
		for tile: Vector2i in _movement_range.range_tiles:
			var dist: int = GameState.current_level.grid.get_tile_distance(tile, _target.current_tile, true)
			var dist_actual: int = GameState.current_level.grid.get_tile_distance(tile, _target.current_tile)
			# add marginal favorability to direct approach
			if dist_actual > dist or dist_actual == -1:
				if dist_actual > 0:
					dist = min(dist + 1, dist_actual)
				else:
					dist = dist + 1
			
			if dist < min_distance:
				min_distance = dist
				desired_tile = tile
	else:
		var desired_favoribility: float = 0
		var move_tiles: Array[Vector2i] = _movement_range.range_tiles.duplicate()
		move_tiles.shuffle()
		for tile in move_tiles:
			var skill_state: SkillState = _enemy.active_skill.state.new(_enemy, _enemy.active_skill, _target.current_tile, tile)
			var skill_range := GameState.current_level.grid.request_range(tile, _enemy.active_skill.min_range, _enemy.active_skill.max_range, _enemy.active_skill.range_shape, true, _enemy.active_skill.direct)
			if not _target in skill_state.targets or not skill_state.can_use(skill_range) == Global.SkillErrorCode.OK:
				continue
			var likelihood: float = skill_state.calc_skill_likelihood(_turn_history)
			if likelihood == 0:
				continue
			
			# multiply by .1 to normalize at a value less than skill likelihood
			var tile_distance: float = GameState.current_level.grid.get_tile_distance(_enemy.current_tile, tile)
			var distance_preference: float = tile_distance / float(_enemy.movement_range) * Enemy.DISTANCE_PRIORITY
			likelihood += Enemy.DISTANCE_PRIORITY - distance_preference
			# prioritize using max skill range for ranged attacks
			var target_distance: float = GameState.current_level.grid.get_tile_distance(_target.current_tile, tile, _enemy.active_skill.direct)
			var range_preference: float = (target_distance / _enemy.active_skill.max_range) * _enemy.safety_priority
			likelihood += range_preference
			if likelihood > desired_favoribility:
					desired_tile = tile
					desired_favoribility = likelihood
	
	return desired_tile


func _wait(delta: float) -> void:
	if not _has_highlighted:
		_movement_range = RangeStruct.new()
		_has_highlighted = true
		_highlight_targets(_target.current_tile)
	_time_highlight += delta
	if _character.facing != Vector2i(VectorF.snap_direction(_target.current_tile - _enemy.current_tile)):
		_character.facing = Vector2i(VectorF.snap_direction(_target.current_tile - _enemy.current_tile))
	_character.animator.play_directional("idle", _character.facing)

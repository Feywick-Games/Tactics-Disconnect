class_name Grid
extends AStarGrid2D

var _unit_registry: Dictionary[Vector2i, Character]
var _enemy_tiles: Array[Vector2i]
var enemy_tiles: Array[Vector2i]:
	get:
		return _enemy_tiles
var _ally_tiles: Array[Vector2i]
var ally_tiles: Array[Vector2i]:
	get:
		return _ally_tiles
var _prop_tiles: Array[Vector2i]


func _init() -> void:
	region = Rect2i()
	default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	cell_size = Global.TILE_SIZE
	diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	update()


func update_region(rect: Rect2i) -> void:
	region = rect
	update()


func _on_unit_died(unit: Character) -> void:
	for cur_tile: Vector2i in _unit_registry.keys():
		if _unit_registry[cur_tile] == unit:
			set_point_solid(cur_tile, false)
			_unit_registry.erase(cur_tile)


func update_unit_registry(tile: Vector2i, unit: Character) -> void:
	if unit is Ally:
		_ally_tiles.append(tile)
	else:
		_enemy_tiles.append(tile)
	
	if not unit.died.is_connected(_on_unit_died.bind(unit)):
		unit.died.connect(_on_unit_died.bind(unit))
	
	for cur_tile: Vector2i in _unit_registry.keys():
		if _unit_registry[cur_tile] == unit:
			set_point_solid(cur_tile, false)
			_unit_registry.erase(cur_tile)
			if unit is Ally:
				_ally_tiles.remove_at(_ally_tiles.find(cur_tile))
			else:
				_enemy_tiles.remove_at(_enemy_tiles.find(cur_tile))
	
	set_point_solid(tile, true)
	_unit_registry[tile] = unit


func add_cell(tile: Vector2i) -> void:
	set_point_solid(tile, false)


func lock_cell(tile: Vector2i) -> void:
	set_point_solid(tile, true)


func add_prop(tile: Vector2i) -> void:
	set_point_solid(tile, true)
	_prop_tiles.append(tile)


func erase_prop(tile: Vector2i) -> void:
	if is_point_solid(tile):
		set_point_solid(tile, false)
	_prop_tiles.erase(tile)


func get_unit_from_tile(tile: Vector2i) -> Character:
	if _unit_registry.has(tile):
		return _unit_registry[tile]
	else:
		return null
		
		
func get_nearest_available_tile(world_position: Vector2) -> Vector2i:
	var tile := GameState.current_level.world_to_tile(world_position)
	return get_id_path(tile, tile, true)[-1]


func get_tile_distance(start_tile: Vector2i, end_tile: Vector2i, disable_unit_blocks := false) -> int:
	var revert_start := false
	var revert_end := false
	
	if disable_unit_blocks:
		for tile in _unit_registry.keys():
			set_point_solid(_unit_registry[tile].current_tile, false)
			
	
	if is_point_solid(start_tile):
		set_point_solid(start_tile, false)
		revert_start = true
	if is_point_solid(end_tile):
		set_point_solid(end_tile, false)
		revert_end = true
		
	var out : int = get_id_path(start_tile, end_tile).size() - 1
	
	if disable_unit_blocks:
		for tile in _unit_registry.keys():
			set_point_solid(_unit_registry[tile].current_tile)
	
	if revert_start:
		set_point_solid(start_tile)
	if revert_end:
		set_point_solid(end_tile)
	
	return out


func is_path_blocked(from_tile: Vector2i, to_tile: Vector2i, blocked_tiles: Array[Vector2i]) -> bool:
	var start := Vector2(from_tile) 
	var destination := Vector2(to_tile)
	var path := destination - start

	for i in range(1, path.length()):
		var weight : float = i + .45
		var lerp_pos: Vector2 = start.lerp(destination, weight / float(path.length()))
		var point: Vector2i = Vector2i(Vector2(lerp_pos).round())
		
		if region.has_point(point):
			if is_point_solid(point) or point in blocked_tiles:
				return true
	return false


func request_range(unit_tile: Vector2i, min_distance: int, max_distance: int, range_shape: Combat.RangeShape,
is_range := false, direct := false) -> RangeStruct:
	var range_struct := RangeStruct.new()
	var _pass_tiles: Array[Vector2i]
	var _unit_tiles: Array[Vector2i]
	var unit : Character = get_unit_from_tile(unit_tile)
	
	if unit:
		set_point_solid(unit_tile, false)
		_pass_tiles.append(unit_tile)
	
	if is_range:
		for tile in _prop_tiles:
			set_point_solid(tile, false)
			_pass_tiles.append(tile)
		for tile in _unit_registry.keys():
			if tile != unit_tile:
				set_point_solid(tile, false)
				_unit_tiles.append(tile)

	var max_range_rect: Rect2i
	max_range_rect.position = unit_tile - Vector2i(max_distance, max_distance)
	max_range_rect.end = unit_tile + Vector2i(max_distance, max_distance)
	
	
	for y in range(max_range_rect.position.y, max_range_rect.end.y + 1):
		for x in range(max_range_rect.position.x, max_range_rect.end.x + 1):
			if range_shape == Combat.RangeShape.CROSS:
				if x != unit_tile.x and y != unit_tile.y:
					continue
			
			var tile := Vector2i(x,y)
			if region.has_point(tile):
				var id_path: Array[Vector2i] = get_id_path(unit_tile, tile)
				if id_path.size() <= max_distance + 1 and id_path.size() > min_distance:
					if not is_point_solid(tile):
						if not direct:
							range_struct.range_tiles.append(tile)
						else:
							if not is_path_blocked(unit_tile, tile, _unit_tiles):
								range_struct.range_tiles.append(tile)
							else:
								range_struct.blocked_tiles.append(tile)
				elif region.has_point(tile) and id_path.size() == 0 and is_point_solid(tile):
					set_point_solid(tile, false)
					var check_path := get_id_path(unit_tile, tile)
					if check_path.size() <= max_distance + 1 and check_path.size() > min_distance:
						range_struct.blocked_tiles.append(tile)
					set_point_solid(tile, true)

	for tile in _unit_tiles:
		set_point_solid(tile, true)

	for tile in _pass_tiles:
		if tile != unit_tile:
			var tile_idx: int = range_struct.range_tiles.find(tile)
			
			if tile_idx != -1:
				range_struct.range_tiles.remove_at(tile_idx)
				range_struct.blocked_tiles.append(tile)
			
		set_point_solid(tile, true)
	
	if is_range:
		for tile in _unit_tiles:
			set_point_solid(tile, true)
	
	return range_struct

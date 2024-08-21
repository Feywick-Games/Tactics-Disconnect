class_name Level
extends Node2D

const GRID_DRAW_TIME: float = 1

var grid := AStarGrid2D.new()
var grid_complete: bool
var _encounter_started: bool
var _grid_cells: Array[Vector2i]
var _time_since_grid_tile: float = 0
var _current_cell_x: int = 0
var _time_per_grid_tile
var _unit_registry: Dictionary
var _enemy_tiles: Array[Vector2i]
var _ally_tiles: Array[Vector2i]
var _prop_tiles: Array[Vector2i]
var _reverse_build_grid := false

@onready
var _floor_layer: TileMapLayer = $Floor
@onready
var _prop_layer: TileMapLayer = $Props
@onready
var _improvised_weapon_layer: TileMapLayer = $ImprovisedWeapon

@onready
var map: TileMapLayer = $Map


func _ready() -> void:
	grid.region = Rect2i()
	grid.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.cell_size = Global.TILE_SIZE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	GameState.current_level = self
	EventBus.encounter_ended.connect(_on_encounter_ended)
	await get_tree().create_timer(2).timeout
	_on_encounter_started()
	EventBus.encounter_started.emit()


func _on_encounter_ended() -> void:
	_reverse_build_grid = true
	_current_cell_x = grid.region.end.x
	_encounter_started = false
	grid_complete = false


func update_unit_registry(tile: Vector2i, unit: Character) -> void:
	if unit is Ally:
		_ally_tiles.append(tile)
	else:
		_enemy_tiles.append(tile)
	
	if not unit.died.is_connected(_on_unit_died.bind(unit)):
		unit.died.connect(_on_unit_died.bind(unit))
	
	for cur_tile: Vector2i in _unit_registry.keys():
		if _unit_registry[cur_tile] == unit:
			grid.set_point_solid(cur_tile, false)
			_unit_registry.erase(cur_tile)
			if unit is Ally:
				_ally_tiles.remove_at(_ally_tiles.find(cur_tile))
			else:
				_enemy_tiles.remove_at(_enemy_tiles.find(cur_tile))
	
	grid.set_point_solid(tile)
	_unit_registry[tile] = unit
	

func _on_unit_died(unit: Character) -> void:
	for cur_tile: Vector2i in _unit_registry.keys():
		if _unit_registry[cur_tile] == unit:
			grid.set_point_solid(cur_tile, false)
			_unit_registry.erase(cur_tile)


func get_id_path(start_tile: Vector2i, end_tile: Vector2i,  is_ally := false, 
can_pass := false, get_nearest := false) -> Array[Vector2i]:
	var _pass_tiles: Array[Vector2i]
	
	for tile in _unit_registry.keys():
		if _unit_registry[tile] is Ally and (is_ally or can_pass):
			grid.set_point_solid(tile, false)
			_pass_tiles.append(tile)
		elif _unit_registry[tile] is Enemy and (not is_ally or can_pass):
			grid.set_point_solid(tile, false)
			_pass_tiles.append(tile)
	
	if can_pass:
		for tile in _prop_tiles:
			grid.set_point_solid(tile, false)
			_pass_tiles.append(tile)
	
	
	
	var out: Array[Vector2i] = grid.get_id_path(start_tile, end_tile, get_nearest)
	
	
	for tile in _pass_tiles:
		grid.set_point_solid(tile, true)

	return out


func get_unit_from_tile(tile: Vector2i) -> Character:
	if _unit_registry.has(tile):
		return _unit_registry[tile]
	else:
		return null


func world_to_tile(world_position: Vector2) -> Vector2i:
	return map.local_to_map(map.to_local(world_position))


func tile_to_world(tile: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(tile))
	
	
func get_nearest_available_tile(world_position: Vector2) -> Vector2i:
	var tile := world_to_tile(world_position)
	
	return grid.get_id_path(tile, tile, true)[-1]


func _on_encounter_started() -> void:
	grid.clear()
	if not _encounter_started:
		grid_complete = false
	_reverse_build_grid = false
	_populate_grid()
	_encounter_started = true
	_current_cell_x = grid.region.position.x
	_time_per_grid_tile =  GRID_DRAW_TIME/ grid.size.x



func _process(delta: float) -> void:
	if (_encounter_started or _reverse_build_grid) and not grid_complete:
		_time_since_grid_tile += delta
		
		if _time_since_grid_tile > _time_per_grid_tile:
			_time_since_grid_tile = 0
			if not _reverse_build_grid:
				for y in range(grid.region.position.y, grid.region.end.y):
					if not grid.is_point_solid(Vector2i(_current_cell_x,y)):
						if Vector2i(_current_cell_x,y) + Vector2i.UP in _grid_cells:
							map.set_cell(Vector2i(_current_cell_x,y), 0, Vector2.RIGHT)
						else:
							map.set_cell(Vector2i(_current_cell_x,y), 0, Vector2i.ZERO)
				
				_current_cell_x +=  1
			
				if _current_cell_x == grid.region.end.x:
					grid_complete = true
			else:
				for y in range(grid.region.position.y, grid.region.end.y):
					if Vector2i(_current_cell_x,y) in _grid_cells:
						#if Vector2i(_current_cell_x,y) + Vector2i.UP in _grid_cells:
						map.set_cell(Vector2i(_current_cell_x,y))
				
				_current_cell_x -=  1
				
				if _current_cell_x == grid.region.position.x:
					_reverse_build_grid = false
					grid_complete = true


func reset_map() -> void:
	for tile in _grid_cells:
		if tile + Vector2i.UP in _grid_cells:
			map.set_cell(tile, 0, Vector2.ZERO)
		else:
			map.set_cell(tile, 0 , Vector2.RIGHT)


func request_range(unit_tile: Vector2i,min_distance: int, max_distance: int, range_shape: Combat.RangeShape,
is_ally: bool, can_pass := false, include_opponent_tiles := false) -> RangeStruct:
	var range_struct := RangeStruct.new()
	var _pass_tiles: Array[Vector2i]
	
	for tile in _unit_registry.keys():
		if _unit_registry[tile] is Ally and (is_ally or can_pass):
			grid.set_point_solid(tile, false)
			_pass_tiles.append(tile)
		elif _unit_registry[tile] is Enemy and (not is_ally or can_pass):
			grid.set_point_solid(tile, false)
			_pass_tiles.append(tile)
	
	if can_pass:
		for tile in _prop_tiles:
			grid.set_point_solid(tile, false)
			_pass_tiles.append(tile)
	
	var max_range_rect: Rect2i
	max_range_rect.position = unit_tile - Vector2i(max_distance, max_distance)
	max_range_rect.end = unit_tile + Vector2i(max_distance, max_distance)
	
	
	for y in range(max_range_rect.position.y, max_range_rect.end.y + 1):
		for x in range(max_range_rect.position.x, max_range_rect.end.x + 1):
			if range_shape == Combat.RangeShape.CROSS:
				if x != unit_tile.x and y != unit_tile.y:
					continue
			
			var tile = Vector2i(x,y)
			if grid.region.has_point(tile):
				var id_path: Array[Vector2i] = grid.get_id_path(unit_tile, tile)
				if id_path.size() <= max_distance + 1 and id_path.size() > min_distance:
					if not grid.is_point_solid(tile):
						range_struct.range_tiles.append(tile)
				elif tile in _grid_cells and id_path.size() == 0:
					grid.set_point_solid(tile, false)
					var check_path := grid.get_id_path(unit_tile, tile)
					if check_path.size() <= max_distance + 1 and check_path.size() > min_distance:
						range_struct.blocked_tiles.append(tile)
					grid.set_point_solid(tile)

	for tile in _pass_tiles:
		if tile != unit_tile:
			var tile_idx: int = range_struct.range_tiles.find(tile)
			
			if tile_idx != -1:
				range_struct.range_tiles.remove_at(tile_idx)
				range_struct.blocked_tiles.append(tile)
			
		grid.set_point_solid(tile)
		
	if include_opponent_tiles:
		if is_ally:
			for tile in _enemy_tiles:
				var dist: int = abs(tile.y - unit_tile.y) + abs(tile.x - unit_tile.x)
				if dist <= max_distance and dist >= min_distance:
					var tile_idx: int = range_struct.blocked_tiles.find(tile)
					if tile_idx != -1:
						range_struct.blocked_tiles.remove_at(tile_idx)
						range_struct.range_tiles.append(tile)
		else:
			for tile in _ally_tiles:
				var dist: int = abs(tile.y - unit_tile.y) + abs(tile.x - unit_tile.x)
				if dist <= max_distance and dist >= min_distance:
					var tile_idx: int = range_struct.blocked_tiles.find(tile)
					if tile_idx != -1:
						range_struct.blocked_tiles.remove_at(tile_idx)
						range_struct.range_tiles.append(tile)
	if not unit_tile in range_struct.range_tiles:
		range_struct.range_tiles.append(unit_tile)
	if unit_tile in range_struct.blocked_tiles:
		range_struct.blocked_tiles.erase(unit_tile)
	return range_struct


func draw_range(tiles: Array[Vector2i], atlas_coords: Vector2i) -> void:
	for tile in tiles:
		map.set_cell(tile, 0, atlas_coords)


func select_tile(tile: Vector2i, select := true) -> void:
	
	var atlas_coords: Vector2i = map.get_cell_atlas_coords(tile)
		
	if select:
		atlas_coords.x = 1
		map.set_cell(tile, 0, atlas_coords)
	else:
		atlas_coords.x = 0
		map.set_cell(tile, 0, atlas_coords)


func get_interactable_tiles(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var interactable_tiles: Array[Vector2i]
	for tile in tiles:
		if _improvised_weapon_layer.get_cell_source_id(tile) != -1:
			interactable_tiles.append(tile)
	
	return interactable_tiles



func _populate_grid() -> void:
	var o_rect: Rect2i = _floor_layer.get_used_rect()
	if grid.region.size.x + grid.region.size.y == 0:
		grid.region = o_rect
	else:
		grid.region = grid.region.merge(o_rect)
	grid.update()
	print(grid.region)
	for y:int in range(o_rect.position.y, o_rect.end.y):
		for x:int in range(o_rect.position.x, o_rect.end.x):
			var tile := Vector2i(x,y)
			var source_id = _floor_layer.get_cell_source_id(tile)
			var prop_source_id = _prop_layer.get_cell_source_id(tile)
			var improv_weapon_source_id = _improvised_weapon_layer.get_cell_source_id(tile)
			if source_id == -1 or _floor_layer.get_cell_tile_data(Vector2i(x,y)).get_custom_data("border"):
				grid.set_point_solid(tile)
			else:
				_grid_cells.append(tile)
				if prop_source_id != -1 or improv_weapon_source_id != -1:
					grid.set_point_solid(tile, true)
					_prop_tiles.append(tile)


func get_interactable(tile: Vector2i) -> ImprovisedWeapon:
	var tile_data: TileData = _improvised_weapon_layer.get_cell_tile_data(tile)
	if tile_data:
		return tile_data.get_custom_data("improvised_weapon") as ImprovisedWeapon
	return


func take_interactable(tile: Vector2i) -> ImprovisedWeapon:
	var weapon: ImprovisedWeapon = get_interactable(tile)
	_improvised_weapon_layer.set_cell(tile, -1)
	grid.set_point_solid(tile, false)
	_prop_tiles.erase(tile)
	return weapon

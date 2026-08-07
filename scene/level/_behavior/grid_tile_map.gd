class_name GridTileMap
extends TileMapLayer

const GRID_DRAW_TIME: float = 1

var _encounter_started := false
var _reverse_build_grid := false
var _map_complete := false
var _time_since__grid_tile : float
var _current_cell_x: int = 0
var _time_per_grid_tile: float
var _grid: Grid

@onready
var reticle: TileMapLayer = $ReticleTileMap


func intialize(grid: Grid) -> void:
	_grid = grid

func set_up(set_up_: bool = true) -> void:
	_reverse_build_grid = !set_up_
	_current_cell_x = _grid.region.position.x if set_up_ else _grid.region.end.x
	_time_per_grid_tile =  GRID_DRAW_TIME/ _grid.size.x
	_map_complete = false

func _on_encounter_ended() -> void:
	_reverse_build_grid = true
	_current_cell_x = _grid.region.end.x
	_encounter_started = false
	_map_complete = false

func build() -> void:
	_encounter_started = true


func _process(delta: float) -> void:
	if (_encounter_started or _reverse_build_grid) and not _map_complete:
			_time_since__grid_tile += delta
			
			if _time_since__grid_tile > _time_per_grid_tile:
				_time_since__grid_tile = 0
				if not _reverse_build_grid:
					for y in range(_grid.region.position.y, _grid.region.end.y):
						if not _grid.is_point_solid(Vector2i(_current_cell_x,y)) or  Vector2i(_current_cell_x,y) in _grid.enemy_tiles + _grid.ally_tiles:
							if _grid.region.has_point(Vector2i(_current_cell_x,y) + Vector2i.UP):
								set_cell(Vector2i(_current_cell_x,y), 0, Vector2.RIGHT)
							else:
								set_cell(Vector2i(_current_cell_x,y), 0, Vector2i.ZERO)
					
					_current_cell_x +=  1
				
					if _current_cell_x == _grid.region.end.x:
						_map_complete = true
				else:
					for y in range(_grid.region.position.y, _grid.region.end.y):
						if _grid.region.has_point(Vector2i(_current_cell_x,y)):
							set_cell(Vector2i(_current_cell_x,y))
					
					_current_cell_x -=  1
					
					if _current_cell_x == _grid.region.position.x:
						_reverse_build_grid = false
						_map_complete = true

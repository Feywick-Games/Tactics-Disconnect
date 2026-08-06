class_name ReticleTileMap
extends TileMapLayer


func draw_range(tiles: Array[Vector2i], atlas_coords: Vector2i) -> void:
	for tile in tiles:
		set_cell(tile, 0, atlas_coords)


func select_tile(tile: Vector2i, select := true) -> void:
	
	var atlas_coords: Vector2i = get_cell_atlas_coords(tile)
		
	if select:
		atlas_coords.x = 1
		set_cell(tile, 0, atlas_coords)
	else:
		atlas_coords.x = 0
		set_cell(tile, 0, atlas_coords)

class_name RangeStruct
extends RefCounted

var range_tiles: Array[Vector2i]

func absorb(o_struct: RangeStruct) -> void:
	for valid: Vector2i in o_struct.range_tiles:
		if valid not in range_tiles:
			range_tiles.append(valid)


func get_neighbor(tile: Vector2i, direction: Vector2i) -> Vector2i:
	if tile + direction in range_tiles:
		return tile + direction
	
	direction = Vector2i(VectorF.snap_direction(direction))
	
	var max_perp: int = tile.y if direction in [Vector2i.LEFT, Vector2i.RIGHT] else tile.x
	var max_para: int = tile.x if direction in [Vector2i.LEFT, Vector2i.RIGHT] else tile.y
	var min_perp: int = tile.y if direction in [Vector2i.LEFT, Vector2i.RIGHT] else tile.x
	var min_para: int = tile.x if direction in [Vector2i.LEFT, Vector2i.RIGHT] else tile.y
	
	for range_tile in range_tiles:
		if direction in [Vector2i.LEFT, Vector2i.RIGHT]:
			max_perp = range_tile.y if range_tile.y > max_perp else max_perp
			min_perp = range_tile.y if range_tile.y < min_perp else min_perp
			if direction == Vector2i.LEFT:
				min_para = range_tile.x if range_tile.x < min_para else min_para
			else:
				max_para = range_tile.x if range_tile.x > max_para else max_para 
		else:
			max_perp = range_tile.x if range_tile.x > max_perp else max_perp
			min_perp = range_tile.x if range_tile.x < min_perp else min_perp
			if direction == Vector2i.UP:
				min_para = range_tile.y if range_tile.y < min_para else min_para
			else:
				max_para = range_tile.y if range_tile.y > max_para else max_para 
	
	var perp_size: int = max_perp - min_perp + 1
	var para_size: int = max_para - min_para + 1

	for j: int in range(1,para_size):
		var check_tile: Vector2i = tile + (direction * j) 
		if check_tile in range_tiles:
			return check_tile
	
	for i: int in range(1, floor(perp_size/2.0) + 1):
		var perp_direction : Vector2i = Vector2i.UP if direction in [Vector2i.LEFT, Vector2i.RIGHT] else Vector2i.LEFT
		
		for j: int in range(1,para_size):
			var check_tile: Vector2i = tile + (direction * j) + (perp_direction * i)
			if check_tile in range_tiles:
				return check_tile
		
		for j: int in range(1,para_size):
			var check_tile: Vector2i = tile + (direction * j) - (perp_direction * i)
			if check_tile in range_tiles:
				return check_tile
		
		
	return tile

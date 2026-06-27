class_name RangeStruct
extends RefCounted

var range_tiles: Array[Vector2i]

func absorb(o_struct: RangeStruct) -> void:
	for valid: Vector2i in o_struct.range_tiles:
		if valid not in range_tiles:
			range_tiles.append(valid)
			

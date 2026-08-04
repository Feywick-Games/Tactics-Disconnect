@tool
class_name SpawnPoint
extends Node2D

@export
var is_ally: bool
@export
var spawn_data: Array[SpawnData]
var spawn_positions: Array[Vector2]

func get_units_from_trigger(trigger:SpawnData.Trigger, value: Variant) -> Array[SpawnData]:
	var out: Array[SpawnData]
	
	for data: SpawnData in spawn_data:
		if data.trigger == trigger:
			if data.value == value:
				out.append(data)
			
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	directions.shuffle()
	directions.insert(0, Vector2i.ZERO)
	var direction_occupied : Array[bool] = [false, false, false, false, false]
	
	var spawn_tile: Vector2i = GameState.current_level.world_to_tile(global_position)
	for spawn_datum:SpawnData in out:
		for i in range(len(directions)):
			if not GameState.current_level.grid.is_point_solid(spawn_tile + directions[i]) and not direction_occupied[i]:
				spawn_datum.spawn_global_position = GameState.current_level.tile_to_world(spawn_tile + directions[i])
				direction_occupied[i] = true
				break
	
	return out
	
	
func _draw() -> void:
	if Engine.is_editor_hint():
		if not is_ally:
			draw_circle(Vector2.ZERO, 10, Color.RED)
		else:
			draw_circle(Vector2.ZERO, 10, Color.BLUE)

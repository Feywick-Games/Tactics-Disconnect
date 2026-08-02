@tool
class_name SpawnPoint
extends Node2D

@export
var spawn_data: Array[SpawnData]

func _ready() -> void:
	for spawn_datum:SpawnData in spawn_data:
		spawn_datum.spawn_global_position = global_position 


func get_units_from_trigger(trigger:SpawnData.Trigger, value: Variant) -> Array[SpawnData]:
	var out: Array[SpawnData]
	
	for data: SpawnData in spawn_data:
		if data.trigger == trigger:
			if data.value == value:
				out.append(data)
			
	return out
	
	
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 10, Color.RED)

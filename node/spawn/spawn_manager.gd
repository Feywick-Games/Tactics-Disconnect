class_name SpawnManager
extends Node

var _turn_number : int = 0
var _enemies_remaining : int = 0
var _spawn_points: Array[SpawnPoint]

func _ready() -> void:
	for node: Variant in get_children():
		if node is SpawnPoint:
			_spawn_points.append(node)
	EventBus.encounter_started.connect(_check_spawns)
	EventBus.turn_ended.connect(_check_spawns)


func spawn_unit(spawn_data: SpawnData) -> void:
	var unit: Character = spawn_data.character_scene.instantiate()
	unit.global_position = spawn_data.spawn_global_position
	unit.facing = spawn_data.facing
	unit.died.connect(_update_enemy_count)
	_enemies_remaining += 1
	get_parent().add_child(unit)
	EventBus.unit_spawned.emit(unit)


func get_spawns_from_trigger(trigger: SpawnData.Trigger, value: Variant) -> void:
	var spawns : Array[SpawnData] = []
	for spawn_point: SpawnPoint in _spawn_points:
		spawns.append_array(spawn_point.get_units_from_trigger(trigger, value))
	
	for spawn: SpawnData in spawns:
		spawn_unit(spawn)


func _check_spawns() -> void:
	_turn_number += 1
	get_spawns_from_trigger(SpawnData.Trigger.TURN_NUMBER, _turn_number)
	get_spawns_from_trigger(SpawnData.Trigger.ENEMIES_REMAINING, _enemies_remaining)
	EventBus.spawns_processed.emit()


func _update_enemy_count() -> void:
	_enemies_remaining -= 1

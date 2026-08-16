class_name Level
extends Node2D

const GRID_TILE_MAP_SCENE : PackedScene = preload("res://scene/level/grid_tile_map.tscn")
const GRID_DRAW_TIME: float = 1

@export
var failure_scene : PackedScene = load("res://scene/title_screen/title_screen.tscn")
@export
var success_scene : PackedScene = load("res://scene/title_screen/title_screen.tscn")

var map_complete: bool
var grid: Grid

@onready
var _floor_layer: TileMapLayer = $Floor
@onready
var _prop_layer: TileMapLayer = $Props
@onready
var tracking_cam: TrackingCamera = $TrackingCamera


var ui: CombatUI
var map: GridTileMap
var reticle: ReticleTileMap

var turn_number : int = -1
var active_unit: Character
var unit_spawned := false
var turn_history : Array[TurnData.Serialization]


func _ready() -> void:
	map = GRID_TILE_MAP_SCENE.instantiate()
	_floor_layer.add_child(map)
	reticle = map.reticle
	GameState.current_level = self
	await get_tree().create_timer(2).timeout
	_start_encounter()


func _start_encounter() -> void:
	grid = Grid.new()
	grid.populate(_floor_layer, _prop_layer)
	map.intialize(grid)
	map.set_up(true)
	var state_machine := StateMachine.new(self, LevelSpawnState.new()) 
	add_child(state_machine)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return map.local_to_map(map.to_local(world_position))


func tile_to_world(tile: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(tile))


func reset_map() -> void:
	reticle.clear()


func get_unit_list(ordered := true) -> Array[Character]:
	var units : Array[Character]
	for node: Node in get_tree().get_nodes_in_group("ally") + get_tree().get_nodes_in_group("enemy"):
		if not node.is_queued_for_deletion():
			units.append(node as Character)
	
	if ordered:
		var unit_idx : int = units.find(active_unit)		
		var ordered_units : Array[Character] = units.slice(unit_idx)
		ordered_units.append_array(units.slice(0, unit_idx))
		units = ordered_units
	return units

class_name Level
extends Node2D

@export_file("*.tscn")
var failure_scene := "res://scene/title_screen/title_screen.tscn"
@export_file("*.tscn")
var success_scene := "res://scene/title_screen/title_screen.tscn"

signal scene_change_requested(scene: PackedScene)

const GRID_TILE_MAP_SCENE : PackedScene = preload("res://scene/level/grid_tile_map.tscn")
const GRID_DRAW_TIME: float = 1

var _turn_number : int = -1

var map_complete: bool
var grid: Grid

@onready
var _floor_layer: TileMapLayer = $Floor
@onready
var _prop_layer: TileMapLayer = $Props
@onready
var _tracking_cam: TrackingCamera = $TrackingCamera
@onready

var ui: CombatUI

var map: GridTileMap
var reticle: ReticleTileMap
var _active_unit: Character
var _is_player_phase := true
var _spawn_processed := false
var _enemy_spawned := false


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
	_process_spawns()
	

func _check_unit_count() -> void:
	var ally_count: int = get_tree().get_node_count_in_group("ally")
	var enemy_count: int = get_tree().get_node_count_in_group("enemy")
	
	if enemy_count == 0:
		var spawn_points : Array[SpawnPoint]
		for child: Node in find_children("*", "SpawnPoint"):
			spawn_points.append(child as SpawnPoint)
		
		var spawns_remaining := false
		for spawn_point: SpawnPoint in spawn_points:
			if not spawn_point.spawn_data.is_empty():
				spawns_remaining = true
				break
		
		if not spawns_remaining:
			win()
			return
	
	if ally_count == 0:
		lose()


func win() -> void:
	scene_change_requested.emit(success_scene)


func lose() -> void:
	scene_change_requested.emit(failure_scene)


#region Spawn Processing

func _process_spawns() -> void:
	
	var ordered_units : Array [Character] = _get_unit_list()
	if _active_unit is Ally and ordered_units[1] is Enemy:
		_is_player_phase = false
	if _active_unit is Enemy and ordered_units[1] is Ally:
		_is_player_phase = true
		_spawn_processed = false
	
	if not _is_player_phase or _spawn_processed:
		_process_skill_selection()
		return
	
	_turn_number += 1
	ui.skill_progress.increment()
	_spawn_processed = true
	var spawn_points : Array[SpawnPoint]
	for child: Node in find_children("*", "SpawnPoint"):
		spawn_points.append(child as SpawnPoint)
	await _spawn_from_trigger(spawn_points, SpawnData.Trigger.TURN_NUMBER, _turn_number)
	var enemies_remaining: int = get_tree().get_nodes_in_group("enemy").size()
	await _spawn_from_trigger(spawn_points, SpawnData.Trigger.ENEMIES_REMAINING, enemies_remaining)
	_process_skill_selection()


func _spawn_from_trigger(spawn_points: Array[SpawnPoint], trigger: SpawnData.Trigger, value: Variant) -> void:
	for spawn_point: SpawnPoint in spawn_points:
		var spawns : Array[SpawnData] = spawn_point.get_units_from_trigger(trigger, value)
		if not spawns.is_empty():
			_tracking_cam.follow(spawn_point)
			await _tracking_cam.position_reached
			for spawn: SpawnData in spawns:
				_spawn_unit(spawn)
				_enemy_spawned = true


func _spawn_unit(spawn_data: SpawnData) -> void:
	var unit: Character = spawn_data.character_scene.instantiate()
	unit.global_position = spawn_data.spawn_global_position
	unit.facing = spawn_data.facing
	unit.died.connect(_check_unit_count)
	add_child(unit)
	await unit.spawn_completed

#endregion

#region Skill Selection

func _process_skill_selection() -> void:
	if not (ui.skill_progress.is_ready and _is_player_phase):
		_select_action()
		return
	var allies : Array[Ally]
	for node: Node in get_tree().get_nodes_in_group("ally"):
		allies.append(node as Ally)
	ui.skill_select.open(allies)
	ui.combat_panel.hide()
	ui.skill_select.skills_selected.connect(_select_action, CONNECT_ONE_SHOT)

#endregion

#region Process Action

func _select_action() -> void:
	var ordered_units : Array[Character]
	if _enemy_spawned:
		ordered_units = _get_unit_list(false)
		_enemy_spawned = false
	else:
		ordered_units = _get_unit_list()
		var last_unit : Character = ordered_units.pop_front()
		ordered_units.append(last_unit)
	
	_active_unit = ordered_units[0]
	
	ui.start_turn(ordered_units)
	_tracking_cam.follow(_active_unit)
	await _tracking_cam.position_reached
	_active_unit.skill_error_encountered.connect(ui.display_skill_error_code)
	_active_unit.start_turn()
	
	for unit: Character in ordered_units:
		if unit != _active_unit:
			unit.set_state(CharacterWaitState.new(_active_unit.tiles_highlighted))
	
	ui.battle_timer.timed_out.connect(_process_reactions)
	_active_unit.action_selected.connect(_process_action)


func _process_action(skill_state: SkillState) -> void:
	_active_unit.skill_error_encountered.disconnect(ui.display_skill_error_code)
	ui.battle_timer.timed_out.disconnect(_process_reactions)
	_active_unit.action_selected.disconnect(_process_action)
	ui.battle_timer.stop()
	var units: Array[Character] = _get_unit_list()
		
	for unit: Character in units:
		if unit != _active_unit:
			unit.set_state(CharacterWaitState.new(_active_unit.tiles_highlighted))
	
	var minigame_completed: Signal
	
	if not skill_state:
		_process_reactions()
		return
	elif skill_state is BasicSkillState:
		_active_unit.set_state(skill_state)
		_active_unit.action_processed.connect(_process_reactions, CONNECT_ONE_SHOT)
		return
	elif skill_state is PushSkillState:
		minigame_completed = ui.push_progress.completed
		ui.push_progress.start((int(skill_state.skill.push_position.length())))
	
	_active_unit.set_state(skill_state)
	minigame_completed.connect(skill_state.on_minigame_completed)
	if not minigame_completed.is_connected(_process_reactions.unbind(1)):
		minigame_completed.connect(_process_reactions.unbind(1))
	_active_unit.action_processed.connect(_process_reactions)
	
	
#endregion

#region Process Reactions

func _process_reactions() -> void:
	var units: Array[Character] = _get_unit_list()
	var effected_units: Array[Character]
	
	for unit: Character in units:
		if not unit.status.is_empty():
			effected_units.append(unit)
	
	for effected_unit: Character in effected_units:
		for reacting_unit in units:
			if reacting_unit != _active_unit:
				await reacting_unit.process_reactions(effected_unit)
	
	# disconnect turn connections
	_purge_turn_connections()
	_process_spawns()

#endregion

func _purge_turn_connections() -> void:
	if ui.battle_timer.timed_out.is_connected(_process_reactions):
		ui.battle_timer.timed_out.disconnect(_process_reactions)
		_active_unit.set_state(CharacterIdleState.new())
	if _active_unit.action_selected.is_connected(_process_action):
		_active_unit.action_selected.disconnect(_process_action)
	if _active_unit.action_processed.is_connected(_process_reactions):
		_active_unit.action_processed.disconnect(_process_reactions)
	if _active_unit.skill_error_encountered.is_connected(ui.display_skill_error_code):
		_active_unit.skill_error_encountered.disconnect(ui.display_skill_error_code)
	


func world_to_tile(world_position: Vector2) -> Vector2i:
	return map.local_to_map(map.to_local(world_position))


func tile_to_world(tile: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(tile))


func reset_map() -> void:
	reticle.clear()


func get_subtile_position(world_position: Vector2) -> Vector2:
	var tile := world_to_tile(world_position)
	var tile_world_position := tile_to_world(tile)
	var offset: Vector2 = abs(tile_world_position - world_position) / Vector2(Global.TILE_SIZE)
	var out: Vector2
	out.x = fmod(offset.x, 1)
	out.y = fmod(offset.y, 1)
	return out


func _get_unit_list(ordered := true) -> Array[Character]:
	var units : Array[Character]
	for node: Node in get_tree().get_nodes_in_group("ally") + get_tree().get_nodes_in_group("enemy"):
		if not node.is_queued_for_deletion():
			units.append(node as Character)
	
	if ordered:
		var unit_idx : int = units.find(_active_unit)		
		var ordered_units : Array[Character] = units.slice(unit_idx)
		ordered_units.append_array(units.slice(0, unit_idx))
		units = ordered_units
	return units

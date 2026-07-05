class_name TurnState
extends State

var interacted := false
var acted := false

var _character: Character
var _starting_movement_range: RangeStruct
var _movement_range: RangeStruct
var _attack_range: RangeStruct = RangeStruct.new()
var _interactable_range: Array[Vector2i]
var _tile_path: Array[Vector2i]
var _time_since_move: float = 0
var _movement_astar: AStarGrid2D
var _start_tile: Vector2i
var _exiting := false
var _encounter_ended := false
var _highlighted_tile: Vector2i
var _moving := false

func enter() -> void:
	_character = state_machine.state_owner as Character
	_start_tile = _character.current_tile
	_highlighted_tile = _start_tile
	_character.start_turn()
	EventBus.encounter_ended.connect(_on_encounter_ended)
	calc_default_ranges()
	
	_character.animator.play_directional("idle")
	
	_starting_movement_range = _movement_range


# caculates movement and interactable ranges. Generates astars
func calc_default_ranges() -> void:
	_movement_range = GameState.current_level.grid.request_range(_character.current_tile, 0, _character.movement_range, Combat.RangeShape.DIAMOND)
	_starting_movement_range = _movement_range
	_interactable_range = GameState.current_level.get_interactable_tiles(_movement_range.range_tiles)
	if _character.movement_range > 0:
		_movement_astar = _character.create_range_astar(_movement_range, _character.movement_range)


func update(_delta: float) -> State:
	if _encounter_ended:
		return _character.init_state.new()
	elif _exiting and not _moving:
		_character.end_turn()
		if not _encounter_ended:
			return CharacterCombatIdleState.new()
	return


func physics_update(delta: float) -> State:
	_tile_path =  _character.process_movement(delta, _tile_path)
	if _tile_path.is_empty():
		_moving = false
	return


func end_turn() -> void:
	_exiting = true
	
func exit() -> void:
	GameState.current_level.reset_map()
	
	
func _on_encounter_ended() -> void:
	_encounter_ended = true
	_character.end_encounter()
	
	
	
func _highlight_targets(target_tile: Vector2i) -> void:
	var direction: Vector2 = VectorF.snap_direction(target_tile - _character.current_tile)
	var aoe: Array[Vector2i]
	var range_type: Combat.RangeType
	
	var highlighted_tiles: Array[Vector2i]
	GameState.current_level.reset_map()
	_character.update_ranges(_movement_range, _interactable_range)
	var status_effects: Array[StatusEffect]
	
	if not GameState.current_level.get_interactable(target_tile):
		if _character.attack_state == Combat.AttackState.BASIC:
			aoe = _character.basic_skill.aoe
			range_type = _character.basic_skill.range_type
			status_effects = _character.basic_skill.status_effects
		elif _character.attack_state == Combat.AttackState.SPECIAL:
			aoe = _character.special.aoe
			range_type = _character.special.range_type
			status_effects = _character.special.status_effects
		elif _character.attack_state == Combat.AttackState.ITEM:
			aoe = _character.item.aoe
			range_type = _character.item.range_type
			status_effects = _character.item.status_effects

		
		for tile_offset in aoe:
			var tile: Vector2i
			var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(direction.angle()).round())
			if range_type == Combat.RangeType.MELEE:
				tile = _character.current_tile + Vector2i(direction) + offset_rotated
			else:
				tile = target_tile + offset_rotated
			
			highlighted_tiles.append(tile)
			
			if not tile in _attack_range.range_tiles:
				var is_valid := GameState.current_level.grid.region.has_point(tile) \
				and not GameState.current_level.grid.is_point_solid_ignore_unit(tile)
				
				if not is_valid:
					continue
				

			GameState.current_level.select_tile(tile)
	else:
		GameState.current_level.select_tile(target_tile)

	EventBus.tiles_highlighted.emit(highlighted_tiles, status_effects, _character.accuracy, Vector2i(direction), _character is Ally)

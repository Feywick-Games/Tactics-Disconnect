class_name TurnState
extends State

var interacted := false
var acted := false

var _character: Character
var _starting_movement_range: RangeStruct
var _movement_range: RangeStruct
var _attack_range: RangeStruct = RangeStruct.new()
var _tile_path: Array[Vector2i]
var _movement_astar: AStarGrid2D
var _start_tile: Vector2i
var _exiting := false
var _encounter_ended := false
var _highlighted_tile: Vector2i
var _skill_highlight_range: SkillHighlightRange
var _moving := false
var _turn_data: TurnData

func _init(turn_data: TurnData, highlight_range: SkillHighlightRange) -> void:
	_skill_highlight_range = highlight_range
	_turn_data = turn_data


func enter() -> void:
	_character = state_machine.state_owner as Character
	_start_tile = _character.current_tile
	_highlighted_tile = _start_tile
	calc_default_ranges()
	_character.animator.play_directional("idle")
	_starting_movement_range = _movement_range


# caculates movement and interactable ranges. Generates astars
func calc_default_ranges() -> void:
	_movement_range = GameState.current_level.grid.request_range(_character.current_tile, 0, _character.movement_range, Combat.RangeShape.DIAMOND)
	_starting_movement_range = _movement_range
	if _character.movement_range > 0:
		_movement_astar = _character.create_range_astar(_movement_range, _character.movement_range)


func update(_delta: float) -> State:
	if _encounter_ended:
		return CharacterIdleState.new()
	elif _exiting and not _moving:
		_character.end_turn()
		if not _encounter_ended:
			return CharacterIdleState.new()
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
	
	


func _highlight_targets(target_tile: Vector2i) -> void:
	var direction: Vector2 = VectorF.snap_direction(target_tile - _character.current_tile)
	
	GameState.current_level.reset_map()
	_character.update_ranges(_movement_range)
		
	var highlighted_tiles: Array[Vector2i] = _character.active_skill.highlight_targets(_character.current_tile, target_tile, _attack_range.range_tiles, direction)

	_character.tiles_highlighted.emit(highlighted_tiles, _character.active_skill.status_effects, Vector2i(direction), _character is Ally)

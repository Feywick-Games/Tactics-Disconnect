class_name TurnState
extends State

signal skill_error_encountered

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
var _moving := false
var _turn_data: TurnData
var _turn_history: Array[TurnData.Serialization]

func _init(turn_data: TurnData, turn_history: Array[TurnData.Serialization]) -> void:
	_turn_data = turn_data
	_turn_history = turn_history


func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.health_bar.value = _character.health
	_character.active_skill = _character.basic_skill
	_character.show_health_bar(true)
	_start_tile = _character.current_tile
	_highlighted_tile = _start_tile
	_calc_default_ranges()
	_character.animator.play_directional("move_idle")
	_starting_movement_range = _movement_range


# caculates movement and interactable ranges. Generates astars
func _calc_default_ranges() -> void:
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


func _select_action(tile: Vector2i, attack_range: RangeStruct, state: TurnState) -> State:
	if tile in attack_range.range_tiles:
		var skill_state : SkillState = _character.active_skill.state.new(_character, _character.active_skill, tile)
		var can_use: Global.SkillErrorCode = skill_state.can_use(attack_range)
		
		
		if can_use == Global.SkillErrorCode.OK:
			_character.facing = Vector2i(Vector2(tile - _character.current_tile).normalized().round())
			return skill_state
		else:
			skill_error_encountered.emit(can_use)
	return


func _highlight_targets(target_tile: Vector2i) -> void:
	var direction: Vector2 = VectorF.snap_direction(target_tile - _character.current_tile)
	
	GameState.current_level.reset_map()
	_character.update_ranges(_movement_range)
		
	_character.active_skill.highlight_targets(_character.current_tile, target_tile, _attack_range.range_tiles, direction)

	_turn_data.active_skill_state = _character.active_skill.state.new(_character, _character.active_skill, target_tile)

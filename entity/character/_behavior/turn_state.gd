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
var _moving := false

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
	_character.action_selected.emit(null)
	GameState.current_level.reset_map()
	
	


func _highlight_targets(target_tile: Vector2i) -> void:
	var direction: Vector2 = VectorF.snap_direction(target_tile - _character.current_tile)
	
	GameState.current_level.reset_map()
	_character.update_ranges(_movement_range)
	var skill: Skill
	
	if _character.attack_state == Combat.AttackState.BASIC:
		skill = _character.basic_skill
	elif _character.attack_state == Combat.AttackState.SPECIAL:
		skill = _character.special
	elif _character.attack_state == Combat.AttackState.ITEM:
		skill = _character.item
		
	var highlighted_tiles: Array[Vector2i] = skill.highlight_targets(_character.current_tile, target_tile, _attack_range.range_tiles, direction)

	_character.tiles_highlighted.emit(highlighted_tiles, skill.status_effects, Vector2i(direction), _character is Ally)

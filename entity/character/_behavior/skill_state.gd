@abstract
class_name SkillState
extends State

const DEFAULT_DESIRED_TARGET_PCT: float = .5

var _character: Character
var _target_tile: Vector2i
var skill: Skill
var _turn_data: PhaseData
var _desired_target_count: int
var mini_game: MiniGame
var impact_time: float = 1.0
var _direction: Vector2i
var _time_in_state: float

func _init(character: Character, i_skill: Skill, target_tile: Vector2i, turn_data: PhaseData) -> void:
	_target_tile = target_tile
	skill = i_skill
	_desired_target_count = round(skill.aoe.size() * DEFAULT_DESIRED_TARGET_PCT)
	_character = character
	_turn_data = turn_data


func update(delta: float) -> State:
	_time_in_state = _time_in_state + delta
	if _time_in_state > impact_time and PhaseData.Event.IMPACT not in _turn_data.events:
		_turn_data.events.append(PhaseData.Event.IMPACT)
	return


func enter() -> void:
	super.enter()
	_direction = VectorF.snap_direction(_target_tile - _character.current_tile)
	_character.animator.play_directional(skill.character_animation, _direction)
	impact_time = _character.get_impact_time(_character.animator.current_animation)


func exit() -> void:
	super.exit()
	_character.end_turn()
	if _character is Ally:
		if skill == _character.special:
			_character.special = null


func calc_skill_likelihood(strike_tile : Vector2i) -> float:
	var attack_range : RangeStruct = GameState.current_level.grid.request_range(
		strike_tile, skill.min_range, skill.max_range, skill.range_shape, true, skill.direct
	)
	

	for tile in attack_range.range_tiles:
		var target_count: int = 0
		var has_unit := false
		var direction := VectorF.snap_direction(Vector2(tile - strike_tile))
		var last_target_tile: Vector2i = Vector2i.UP
		for target_tile in skill.aoe:
			target_tile = Vector2i(Vector2(target_tile).rotated(direction.angle()))
			if target_tile == last_target_tile:
				printerr("counted tile twice")
			
			var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile + target_tile)
			if unit != self and (unit is Ally) != (_character is Ally):
				target_count +=1
				if tile + target_tile == _target_tile:
					has_unit = true
				if target_count >= _desired_target_count and has_unit:
					return 1
			last_target_tile = target_tile
	return 0


func can_use() -> Global.SkillErrorCode:
	var target: Character
	
	for aoe_tile in skill.aoe:
		var offset_rotated: = Vector2i(Vector2(aoe_tile).rotated(Vector2(_character.facing).angle()).round())
		target = GameState.current_level.grid.get_unit_from_tile(_target_tile + offset_rotated)
		if target:
			break
	
	if not target:
		return Global.SkillErrorCode.NO_TARGET
	
	var can_move : bool = true
		
	if skill.move_position != Vector2i.ZERO:
		can_move = false
		var move_tile: Vector2i  = Vector2i(Vector2(skill.move_position).rotated(Vector2(_character.facing).angle()).round())
		move_tile = _character.current_tile + move_tile
		if (skill.direct and not GameState.current_level.grid.is_point_solid_ignore_unit(move_tile)) \
		or (not skill.direct and GameState.current_level.grid.is_point_solid(move_tile)):
			can_move = true
	
	if not can_move:
		return Global.SkillErrorCode.MOVE_BLOCKED
	
	return Global.SkillErrorCode.OK

class_name SkillState
extends State

var _character: Character
var _target_tile: Vector2i
var _skill: Skill
var _action_to_process: int = 1
var _exiting := false
var _desired_target_count: int

func _init(character: Character, skill: Skill, target_tile: Vector2i) -> void:
	_target_tile = target_tile
	_skill = skill
	_desired_target_count = round(_skill.aoe.size() * .75)
	_character = character

func enter() -> void:
	EventBus.skill_display_requested.emit(_skill.name)


func update(_delta: float) -> State:
	if _exiting:
		_character.end_turn()
		return CharacterCombatIdleState.new()
	return


func end_turn() -> void:
	_action_to_process -=1
	if _action_to_process == 0:
		_exiting = true
	

func exit() -> void:
	super.exit()
	if _character is Ally:
		if _skill == _character.special:
			_character.special = null


func calc_skill_likelihood(strike_tile : Vector2i) -> float:
	var attack_range : RangeStruct = GameState.current_level.grid.request_range(
		strike_tile, _skill.min_range, _skill.max_range, _skill.range_shape, true, _skill.direct
	)
	

	for tile in attack_range.range_tiles:
		var target_count: int = 0
		var has_unit := false
		var direction := VectorF.snap_direction(Vector2(tile - strike_tile))
		var last_target_tile: Vector2i = Vector2i.UP
		for target_tile in _skill.aoe:
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


func can_use(target_tile: Vector2i) -> Global.SkillErrorCode:
	var target: Character
	
	for aoe_tile in _skill.aoe:
		var offset_rotated: = Vector2i(Vector2(aoe_tile).rotated(Vector2(_character.facing).angle()).round())
		target = GameState.current_level.grid.get_unit_from_tile(target_tile + offset_rotated)
		if target:
			break
	
	if not target:
		return Global.SkillErrorCode.NO_TARGET
	
	var can_move : bool = true
		
	if _skill.move_position != Vector2i.ZERO:
		can_move = false
		var move_tile: Vector2i  = Vector2i(Vector2(_skill.move_position).rotated(Vector2(_character.facing).angle()).round())
		move_tile = _character.current_tile + move_tile
		if (_skill.direct and GameState.current_level.grid.is_point_solid_ignore_unit(move_tile)) \
		or (not _skill.direct and GameState.current_level.grid.is_point_solid(move_tile)):
			can_move = true
	
	if not can_move:
		return Global.SkillErrorCode.MOVE_BLOCKED
	
	return Global.SkillErrorCode.OK

class_name SkillState
extends State

signal impact

const DEFAULT_DESIRED_TARGET_PCT: float = .75

var _character: Character
var target_tile: Vector2i
var targets: Array[Character]
var skill: Skill
var _desired_target_count: int
var mini_game: MiniGame
var ui: CombatUI
var impact_time: float = 1.0
var _direction: Vector2i
var _time_in_state: float
var _multiplier: float = 1.0
var _impact_emitted := false
var _started := false


func _init(character: Character, i_skill: Skill, target_tile_: Vector2i) -> void:
	target_tile = target_tile_
	skill = i_skill
	_desired_target_count = round(skill.aoe.size() * DEFAULT_DESIRED_TARGET_PCT)
	_character = character


func enter() -> void:
	super.enter()
	_direction = VectorF.snap_direction(target_tile - _character.current_tile)
	impact_time = _character.get_impact_time(_character.animator.get_directional_animation_name(skill.character_animation, _direction))
	if skill.name != "":
		_character.request_skill_text(skill.name)
	_set_targets()


func update(delta: float) -> State:
	if _started:
		_time_in_state = _time_in_state + delta
	if _time_in_state > impact_time and not _impact_emitted:
		impact.emit()
		_impact_emitted = true
	return


func _hit_targets() -> void:
	for target in targets:
		var damage_state := DamageState.new(skill, _direction, impact, _multiplier)
		target.set_state(damage_state)


func _set_targets() -> void:
	for tile_offset in skill.aoe:
		var tile: Vector2i
		var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(Vector2(_direction).angle()).round())
		if skill.range_type == Combat.RangeType.MELEE:
			tile = _character.current_tile + Vector2i(_direction) + offset_rotated
		else:
			tile = target_tile + offset_rotated
		var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile)
		if unit:
			targets.append(unit)


func on_cheer(success: bool) -> void:
	if success:
		_multiplier += .25


func on_get_behind_me(pause: bool) -> void:
	play(pause)


func exit() -> void:
	super.exit()
	_character.end_turn()
	if _character is Ally:
		if skill == _character.special:
			_character.special = null


func calc_skill_likelihood(strike_tile : Vector2i) -> float:
	
	if not can_use() == Global.SkillErrorCode.OK:
		return 0
	
	var attack_range : RangeStruct = GameState.current_level.grid.request_range(
		strike_tile, skill.min_range, skill.max_range, skill.range_shape, true, skill.direct
	)
	
	for tile in attack_range.range_tiles:
		var target_count: int = 0
		var direction := VectorF.snap_direction(Vector2(tile - strike_tile))
		for aoe_tile in skill.aoe:
			aoe_tile = Vector2i(Vector2(aoe_tile).rotated(direction.angle()))
			var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile + aoe_tile)
			if unit != self and (unit is Ally) != (_character is Ally):
				target_count +=1
				# NOTICE: removed the requirement to have a target in the target tile
				if target_count >= _desired_target_count:
					return 1
	return 0


func can_use() -> Global.SkillErrorCode:
	var target: Character
	
	for aoe_tile in skill.aoe:
		var offset_rotated: = Vector2i(Vector2(aoe_tile).rotated(Vector2(_character.facing).angle()).round())
		target = GameState.current_level.grid.get_unit_from_tile(target_tile + offset_rotated)
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


func play(pause:=false) -> void:
	state_machine.set_process(!pause)
	state_machine.set_physics_process(!pause)
	if pause:
		_character.animator.pause()
	else:
		_character.animator.play()

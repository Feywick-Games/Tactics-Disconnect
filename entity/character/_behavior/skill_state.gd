class_name SkillState
extends State

signal impact
signal exited

const DEFAULT_DESIRED_TARGET_PCT: float = .75

var _character: Character
var target_tile: Vector2i
var targets: Array[Character]
var skill: Skill
var _desired_target_count: int
var mini_game: MiniGame
var ui: CombatUI
var impact_time: float = 1.0
var direction: Vector2i
var _time_in_state: float
var _impact_emitted := false
var _started := false
var _current_tile : Vector2i
var _cheer_count : int = 0


func _init(character: Character, i_skill: Skill, target_tile_: Vector2i, current_tile_override := Vector2i.MAX) -> void:
	_current_tile = character.current_tile if current_tile_override == Vector2i.MAX else current_tile_override
	target_tile = target_tile_
	_character = character
	skill = i_skill.duplicate(true)
	skill.apply_damage_modifiers(_character.get_modifier(Combat.Status.DAMAGE))
	_desired_target_count = round(skill.aoe.size() * DEFAULT_DESIRED_TARGET_PCT)
	direction = VectorF.snap_direction(target_tile - _current_tile)
	_set_targets()


func enter() -> void:
	super.enter()
	impact_time = _character.get_impact_time(_character.animator.get_directional_animation_name(skill.character_animation, direction))
	var vfx :=  skill.visual_effect_scene.instantiate() as VisualEffect
	vfx.setup(direction, target_tile, skill.aoe, targets, skill.visual_effect_targets_only, impact)
	GameState.current_level.add_child(vfx)
	
	if skill.name != "":
		_character.request_skill_text(skill.name)


func update(delta: float) -> State:
	if _started:
		_time_in_state = _time_in_state + delta
	if _time_in_state > impact_time and not _impact_emitted:
		_impact()
	return


func _impact() -> void:
	impact.emit()
	_impact_emitted = true
	var is_rear_attack := false
	for target: Character in targets:
		if is_equal_approx(Vector2(direction).normalized().dot(Vector2(target.facing).normalized()), 1):
			is_rear_attack = true
			break
	if _character is Ally:
		if mini_game:
			_character.play_actor_status(is_rear_attack, mini_game.ranking != MiniGame.Rank.NORMAL, mini_game.ranking == MiniGame.Rank.NICE, false, _cheer_count)
		else:
			_character.play_actor_status(is_rear_attack, false, false, false, _cheer_count)
	else:
		_character.play_actor_status(is_rear_attack, false, false, true, _cheer_count)


func _hit_targets() -> void:
	for target in targets:
		var damage_state := DamageState.new(skill, direction, impact)
		target.set_state(damage_state)


func _set_targets() -> void:
	for tile_offset in skill.aoe:
		var tile: Vector2i = _get_aoe_tile(target_tile, tile_offset)
		var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile)
		if unit:
			targets.append(unit)


func on_cheer(success: bool) -> void:
	if success:
		_cheer_count += 1
		skill.apply_damage_modifiers(Global.CHEER_MULTIPLIER)


func on_get_behind_me(success: bool) -> void:
	if success:
		pause(true)


func exit() -> void:
	super.exit()
	exited.emit()
	_character.end_turn()
	if _character.special and skill.name == _character.special.name:
		_character.special = null


func calc_skill_likelihood(_turn_history: Array[TurnData.Serialization]) -> float:
	
	var attack_range : RangeStruct = GameState.current_level.grid.request_range(
		_current_tile, skill.min_range, skill.max_range, skill.range_shape, true, skill.direct
	)
	
	if not can_use(attack_range) == Global.SkillErrorCode.OK:
		return 0
	
	for tile in attack_range.range_tiles:
		var target_count: int = 0
		for aoe_tile in skill.aoe:
			aoe_tile = _get_aoe_tile(tile, aoe_tile)
			var unit: Character = GameState.current_level.grid.get_unit_from_tile(aoe_tile)
			if unit != _character and (unit is Ally) != (_character is Ally):
				target_count +=1
				# NOTICE: removed the requirement to have a target in the target tile
				if target_count >= _desired_target_count:
					return .5 + ((float(target_count)/_desired_target_count) * .5)
	return 0


func _get_aoe_tile(tile:Vector2i, offset: Vector2i) -> Vector2i:
	return Vector2i(Vector2(offset).rotated(Vector2(direction).angle()).round()) + tile


func can_use(attack_range: RangeStruct) -> Global.SkillErrorCode:
	var target: Character
	
	if target_tile not in attack_range.range_tiles:
		return Global.SkillErrorCode.UNREACHABLE
	
	for aoe_tile in skill.aoe:
		var tile: = _get_aoe_tile(target_tile, aoe_tile)
		target = GameState.current_level.grid.get_unit_from_tile(tile)
		if target:
			break
	
	if not target:
		return Global.SkillErrorCode.NO_TARGET
	
	var can_move : bool = true
		
	if skill.move_position != Vector2i.ZERO:
		can_move = false
		var move_tile: Vector2i  = Vector2i(Vector2(skill.move_position).rotated(Vector2(_character.facing).angle()).round())
		move_tile = _current_tile + move_tile
		if (skill.direct and not GameState.current_level.grid.is_point_solid_ignore_unit(move_tile)) \
		or (not skill.direct and GameState.current_level.grid.is_point_solid(move_tile)):
			can_move = true
	
	if not can_move:
		return Global.SkillErrorCode.MOVE_BLOCKED
	
	return Global.SkillErrorCode.OK


func pause(yep:=true) -> void:
	state_machine.set_process(!yep)
	state_machine.set_physics_process(!yep)
	if pause:
		_character.animator.pause()
	else:
		_character.animator.play()

class_name PushSkillState
extends SkillState

signal target_collided

const TIME_PER_INCREMENT: float = .3
const TIME_TO_EXIT: float = 1.0
const TIME_TO_PUSH: float = 3.0

var increment: int = 0
var _max_push_distance: int = 0
var _target_unit: Character
var _max_is_collision := false
var _o_target: Character
var _push_distance: int
var _push_tile_path: Array[Vector2i]
var _astar: AStarGrid2D
var _target_collided := false
var pushing: bool = false
var push_time: float

var push_distance: int:
	get:
		return _push_distance
var max_push_distance: int:
	get:
		return _max_push_distance

func _init(character: Character, i_skill: Skill, target_tile_: Vector2i) -> void:
	_push_distance = round(i_skill.push_position.length())
	super._init(character, i_skill, target_tile_)
	push_time = float(_max_push_distance * Global.TILE_SIZE.x) / float(Global.PLAYER_SPEED)


func update(delta: float) -> State:
	if mini_game:
		if mini_game.completed and not pushing:
			pushing = true
			_hit_targets()
		elif _target_collided:
			return CharacterIdleState.new() 
	return super.update(delta)



func _set_targets() -> void:
	super._set_targets()
	_target_unit = GameState.current_level.grid.get_unit_from_tile(target_tile)
	for i in range(1, _push_distance + 1):
		if GameState.current_level.grid.region.has_point(target_tile + (direction * i)) \
		and not GameState.current_level.grid.is_point_solid(target_tile + (direction * i)):
			_max_push_distance += 1
		else:
			break
	
	var collision_point := target_tile + (direction * (_max_push_distance + 1))
	if GameState.current_level.grid.region.has_point(collision_point) and \
	GameState.current_level.grid.is_point_solid(collision_point):
		_max_is_collision = true
		
		var unit := GameState.current_level.grid.get_unit_from_tile(collision_point)
		if unit and unit is Ally != _character is Ally:
			_o_target = unit
			targets.append(unit)


func _hit_targets() -> void:
	var multiplier : int = -Global.MINIGAME_FAILURE_MULTIPLIER if not mini_game.success else Global.MINIGAME_SUCCESS_MULTIPLIER
	skill.apply_damage_modifiers(multiplier)
	_character.animator.play_directional(skill.character_animation, direction)
	_started = true
	
	var skill_range: RangeStruct = GameState.current_level.grid.request_range(target_tile, 0, 
		_max_push_distance, Combat.RangeShape.CROSS, true, true
	)
	_astar = _target_unit.create_range_astar(skill_range, _max_push_distance)
	_push_tile_path = _astar.get_id_path(target_tile, target_tile + (direction * _max_push_distance))	
	var push_damage_state := PushDamageState.new(_push_tile_path, skill, direction, impact)
	push_damage_state.collided.connect(_on_collided)
	_target_unit.set_state(push_damage_state)
	if _o_target:
		var damage_state := DamageState.new(skill, direction, push_damage_state.collided)
		_o_target.set_state(damage_state)
		var vfx :=  skill.visual_effect_scene.instantiate() as VisualEffect
		vfx.setup(direction, _o_target.current_tile, [Vector2i.ZERO], [_o_target], false, push_damage_state.collided)
		GameState.current_level.add_child(vfx)
	if _max_is_collision:
		var vfx :=  skill.visual_effect_scene.instantiate() as VisualEffect
		vfx.setup(direction, _push_tile_path[-1], [Vector2i.ZERO], [_target_unit], false, push_damage_state.collided)
		GameState.current_level.add_child(vfx)


func _on_collided() -> void:
	target_collided.emit()
	_target_collided = true

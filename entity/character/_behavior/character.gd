class_name Character
extends Node2D

signal target_hit

const SNAP_DISTANCE : float = 1.0
const TIME_PER_MOVE := .03
const HEALTH_BAR_PIXEL_WIDTH := 25

@export_category("Debug")
@export_category("UI")
@export
var character_name: String
@export
var turn_portrait_scene: PackedScene
@export
var small_portrait: Texture2D

@export_category("Gameplay")
@export
var facing: Vector2i = Vector2i.DOWN
var init_state: GDScript = CharacterCombatBeginState
@export
var basic_skill: Skill
@export
var special: Skill
@export
var reactions: Array[Reaction]

@export_category("Unit Stats")
@export
var max_health: int = 20
@export
var _movement_range: int = 3
var _movement_modifier: int
var movement_range: int:
	get:
		return _movement_range + _movement_modifier

var health: int
var current_tile: Vector2i
var status: Array[StatusEffect]
var active_skill: Skill
var sub_pixel_position: Vector2
var state_machine: StateMachine

@onready
var sprite: Sprite2D = $CharacterSprite
@onready
var animator: DirectionalAnimator = $ActionAnimator
@onready
var skill_animator: DirectionalAnimator = $SkillAnimator
@onready
var health_bar: TextureProgressBar = $HealthBar
@onready
var damage_bar: TextureProgressBar = $HealthBar/DamageBar
@onready
var status_label_manager: StatusLabelManager = $StatusLabelManager
@onready
var sfx_player: AudioStreamPlayer2D = $SfxPlayer

func _ready() -> void:
	sub_pixel_position = global_position
	health_bar.hide()
	state_machine = StateMachine.new(self, CharacterCombatBeginState.new())
	add_child(state_machine)


func start_encounter() -> void:
	animator.play_directional("idle", facing)
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.step = float(health_bar.max_value) / HEALTH_BAR_PIXEL_WIDTH
	damage_bar.value = health
	damage_bar.max_value = max_health
	damage_bar.step = float(health_bar.max_value) / HEALTH_BAR_PIXEL_WIDTH



func end_encounter() -> void:
	#TODO: A fun animation!
	pass


func get_impact_time(anim_string: String) -> float:
	var impact_time: float = 1
	var anim: Animation = animator.get_animation(anim_string)
	if anim.has_marker("notify_impact"):
		impact_time = anim.get_marker_time("notify_impact")
	else:
		printerr("no marker on: ",character_name , " ", anim_string)
	return impact_time



func _on_display_requested(show_display: bool) -> void:
	if show_display:
		health_bar.show()
	else:
		health_bar.hide()


func process_status_effect(effect: StatusEffect) -> void:
	if effect.status == Combat.Status.HIT:
		health -= effect.value
	elif effect.status == Combat.Status.SLOWED:
		_movement_modifier += effect.value


func start_turn(turn_data: PhaseData, highlight_range: SkillHighlightRange) -> void:
	health_bar.value = health
	active_skill = basic_skill
	health_bar.show()
	
	if self is Ally:
		set_state(AllyTurnState.new(turn_data, highlight_range))
	else:
		set_state(EnemyTurnState.new(turn_data, highlight_range))
	clear_expired_statuses()


func clear_expired_statuses() -> void:
	var statuses_to_remove: Array[StatusEffect]
	
	for status_effect: StatusEffect in status:
		if status_effect.duration == 0:
			statuses_to_remove.append(status_effect)
	
	for status_effect: StatusEffect in statuses_to_remove:
		status.remove_at(status.find(status_effect))



func end_turn() -> void:
	GameState.current_level.grid.update_unit_registry(current_tile, self)	
	health_bar.hide()
	
	for effect: StatusEffect in status:
		effect.duration -= 1


func select_action(tile: Vector2i, attack_range: RangeStruct, state: TurnState, turn_data: PhaseData) -> SkillState:
	var dir := Vector2(tile - current_tile).normalized()
	facing = Vector2i(dir)
	
	animator.play_directional("idle", dir)
	
	if tile in attack_range.range_tiles:
		var skill_state : SkillState = active_skill.state.new(self, active_skill, tile, turn_data)
		var can_use: Global.SkillErrorCode = skill_state.can_use()
		
		
		if can_use == Global.SkillErrorCode.OK:
			facing = Vector2i(Vector2(tile - current_tile).normalized().round())
			return skill_state
		else:
			turn_data.skill_error = can_use
	return


func create_range_astar(range_struct: RangeStruct, manhattan_range: int) -> AStarGrid2D:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(current_tile - Vector2i(manhattan_range, manhattan_range),  (Vector2i(manhattan_range, manhattan_range) * 2) + Vector2i.ONE)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.cell_size = Global.TILE_SIZE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for y in range(astar.region.position.y, astar.region.end.y):
		for x in range(astar.region.position.x, astar.region.end.x):
			if not Vector2i(x,y) in range_struct.range_tiles:
				astar.set_point_solid(Vector2i(x,y))
	return astar


func update_ranges(movement_tiles: RangeStruct) -> RangeStruct:
	# color tiles differently when attacks overlap with movement 
	var skill_range: Array[Vector2i]
	var aoe: Array[Vector2i]
	
	skill_range = GameState.current_level.grid.request_range(current_tile, active_skill.min_range, active_skill.max_range, active_skill.range_shape, true, active_skill.direct).range_tiles
	
	skill_range.erase(current_tile)
	
	var skill_aoe_range : Array[Vector2i]
	for range_tile: Vector2i in skill_range:
		for tile_offset in aoe:
			var direction : Vector2 = VectorF.snap_direction(Vector2(range_tile - current_tile).normalized())
			var tile: Vector2i
			var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(direction.angle()).round())
			tile = range_tile + offset_rotated
			var is_valid := GameState.current_level.grid.region.has_point(tile) \
			and not GameState.current_level.grid.is_point_solid_ignore_unit(tile)
			
			if is_valid and not tile in skill_range and not tile in skill_aoe_range:
				skill_aoe_range.append(tile)
	
	var overlap_tiles: Array[Vector2i]
	var attack_only_tiles: Array[Vector2i]
	
	for tile in skill_range + skill_aoe_range:
		if tile in movement_tiles.range_tiles:
			overlap_tiles.append(tile)
		else:
			attack_only_tiles.append(tile)
	
	var overlap_atlas_coords: Vector2i
	if active_skill == basic_skill:
		overlap_atlas_coords = Global.RETICLE_OVERLAP_BASIC_ATLAS_COORDS
	else:
		overlap_atlas_coords = Global.RETICLE_OVERLAP_SPECIAL_ATLAS_COORDS
	
	GameState.current_level.reset_map()
	GameState.current_level.reticle.draw_range(movement_tiles.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	active_skill.draw_range(attack_only_tiles, active_skill == special)
	GameState.current_level.reticle.draw_range(overlap_tiles, overlap_atlas_coords)
	if not movement_tiles.range_tiles.is_empty():
		GameState.current_level.reticle.set_cell(current_tile, 0, Global.RETICLE_MOVE_ALTAS_COORDS)
		GameState.current_level.reticle.select_tile(current_tile)
	
	var out := RangeStruct.new()
	out.range_tiles = skill_range
	return out


func process_movement(delta: float, tile_path: Array[Vector2i], animation := "idle") -> Array[Vector2i]:
	if not tile_path.is_empty():
		var path_position :=  GameState.current_level.tile_to_world(tile_path[0])
		var map_position := GameState.current_level.tile_to_world(current_tile)
		if path_position.distance_to(global_position) > SNAP_DISTANCE:
			var dir: Vector2 = (path_position - global_position).normalized()
			sub_pixel_position += dir * Global.PLAYER_SPEED * delta
			global_position = sub_pixel_position.round()
			var anim_dir := Vector2(tile_path[0] - current_tile).normalized()
			if not animation.is_empty():
				animator.play_directional(animation, anim_dir)
		if not path_position.distance_to(global_position) > SNAP_DISTANCE:
			if len(tile_path) == 1:
				sub_pixel_position = path_position
				global_position = sub_pixel_position.round()
			tile_path.pop_front()
		if not tile_path.is_empty() and \
		path_position.distance_to(global_position) < map_position.distance_to(global_position):
			facing =  tile_path[0] - current_tile
			current_tile = tile_path[0]
			GameState.current_level.grid.update_unit_registry(current_tile, self)
	return tile_path


func take_damage(skill: Skill, direction: Vector2, multiplier: float = 1) -> void:
	multiplier = _calc_damage_multiplier(direction) * multiplier

	for base_effect: StatusEffect in skill.status_effects:
		var new_effect: StatusEffect = base_effect.duplicate()
		new_effect.value = round(new_effect.value * multiplier)
		var statuses : Array[StatusEffect] = status.filter(func(x:StatusEffect) -> bool: return x.status == new_effect.status)
		if statuses.is_empty() :
			status.append(new_effect)
		else:
			statuses[0].duration = max(new_effect.duration, statuses[0].duration)
			status[0].value = max(new_effect.value, statuses[0].value)
		process_status_effect(new_effect)
		status_label_manager.add_status_effect(new_effect)

	health_bar.value = health
	damage_bar.value = health_bar.value
	
	status_label_manager.display_statuses()


func die() -> void:
	GameState.current_level.grid.remove_from_registry(self)
	queue_free()


func set_state(state: State) -> void:
	state_machine.change_state.call_deferred(state)


func highlight(enable := true) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("highlighted", enable)


func _calc_damage_multiplier(direction: Vector2i) -> float:
	var multiplier: float = 1
	if self is Enemy:
		if GameState.battle_timer.value < GameState.battle_timer.max_value * Global.QUICK_TIME_PERCENT:
			multiplier = Global.QUICK_MULTIPLIER
		elif GameState.battle_timer.value > GameState.battle_timer.max_value * Global.SLOW_TIME_PERCENT:
			multiplier = Global.SLOW_MULTIPLIER
	if is_equal_approx(Vector2(direction).normalized().dot(Vector2(facing).normalized()), -1):
		multiplier += Global.BACK_MULTIPLIER
	return multiplier


func display_modified_status(tiles: Array[Vector2i], status_effects: Array[StatusEffect], direction: Vector2i) -> void:
	if current_tile in tiles:
		health_bar.show()
		
		highlight()
	else:
		highlight(false)
		return

	var multiplier: float = _calc_damage_multiplier(direction)

	for base_effect: StatusEffect in status_effects:
		var effect: StatusEffect = base_effect.duplicate()
		effect.value = round(effect.value * multiplier)
		if effect.status == Combat.Status.HIT:
			health_bar.value = health - round(effect.value)
		else:
			status_label_manager.preview(effect)

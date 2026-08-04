class_name Character
extends Node2D

signal died
signal target_hit
@warning_ignore("unused_signal")
signal action_processed
@warning_ignore("unused_signal")
signal spawn_completed
signal skill_error_encountered
signal action_selected(skill_state: SkillState)
signal tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect])

const SNAP_DISTANCE : float = 1.0
const TIME_PER_MOVE := .03
const HEALTH_BAR_PIXEL_WIDTH := 25

@export_category("Debug")
@export
var is_animated := false
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
var attack_state: Combat.AttackState
var item: Item
# TODO remove
var sub_pixel_position: Vector2
var _state_machine: StateMachine

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
	_state_machine = StateMachine.new(self, CharacterCombatBeginState.new())
	add_child(_state_machine)


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


func notify_impact() -> void:
	target_hit.emit()


func _on_display_requested(show_display: bool) -> void:
	if show_display:
		health_bar.show()
	else:
		health_bar.hide()


func drop_weapon() -> void:
	attack_state = Combat.AttackState.BASIC
	item = null
	#TODO play drop animation on skill animator


func process_status_effect(effect: StatusEffect) -> void:
	if effect.status == Combat.Status.HIT:
		health -= effect.value
	elif effect.status == Combat.Status.SLOWED:
		_movement_modifier += effect.value


func start_turn() -> void:
	health_bar.value = health
	
	if self is Ally:
		set_state(AllyTurnState.new())
	else:
		set_state(EnemyTurnState.new())
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

	
	tiles_highlighted.emit([] as Array[Vector2i], [] as Array[StatusEffect], Vector2i.ZERO, false)


func select_action(tile: Vector2i, attack_range: RangeStruct, state: TurnState) -> bool:
	var dir := Vector2(tile - current_tile).normalized()
	facing = Vector2i(dir)
	
	animator.play_directional("idle", dir)
	
	if tile in attack_range.range_tiles:
		var skill: Skill
		
		if attack_state == Combat.AttackState.BASIC:
			skill = basic_skill
		elif attack_state == Combat.AttackState.SPECIAL:
			skill = special
		elif attack_state == Combat.AttackState.ITEM:
			skill = item
		
		var skill_state : SkillState = skill.state.new(self, skill, tile)
		var can_use: Global.SkillErrorCode = skill_state.can_use(tile)
		
		
		if can_use == Global.SkillErrorCode.OK:
			facing = Vector2i(Vector2(tile - current_tile).normalized().round())
			action_selected.emit(skill_state)
			return true
			
		else:
			skill_error_encountered.emit(can_use)


	elif GameState.current_level.get_interactable(tile):
		item = GameState.current_level.take_interactable(tile)
		attack_state = Combat.AttackState.ITEM
		state.interacted = true
	
	return false


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
	var skill: Skill
	var skill_range: Array[Vector2i]
	var aoe: Array[Vector2i]
	
	if attack_state == Combat.AttackState.BASIC:
		skill = basic_skill
	elif attack_state == Combat.AttackState.SPECIAL:
		skill = special
	elif attack_state == Combat.AttackState.ITEM:
		skill = item
	
	skill_range = GameState.current_level.grid.request_range(current_tile, skill.min_range, skill.max_range, skill.range_shape, true, skill.direct).range_tiles
	
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
	if attack_state == Combat.AttackState.BASIC:
		overlap_atlas_coords = Global.RETICLE_OVERLAP_BASIC_ATLAS_COORDS
	else:
		overlap_atlas_coords = Global.RETICLE_OVERLAP_SPECIAL_ATLAS_COORDS
	
	GameState.current_level.reset_map()
	GameState.current_level.reticle.draw_range(movement_tiles.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	skill.draw_range(attack_only_tiles, attack_state == Combat.AttackState.SPECIAL)
	GameState.current_level.reticle.draw_range(overlap_tiles, overlap_atlas_coords)
	if not movement_tiles.range_tiles.is_empty():
		GameState.current_level.reticle.set_cell(current_tile, 0, Global.RETICLE_MOVE_ALTAS_COORDS)
		GameState.current_level.reticle.select_tile(current_tile)
	
	var out := RangeStruct.new()
	out.range_tiles = skill_range
	return out


func process_movement(delta: float, tile_path: Array[Vector2i], animation := "idle", skip_animation := false) -> Array[Vector2i]:
	if not tile_path.is_empty():
		var path_position :=  GameState.current_level.tile_to_world(tile_path[0])
		var map_position := GameState.current_level.tile_to_world(current_tile)
		if path_position.distance_to(global_position) > SNAP_DISTANCE:
			var dir: Vector2 = (path_position - global_position).normalized()
			sub_pixel_position += dir * Global.PLAYER_SPEED * delta
			print(sub_pixel_position)
			global_position = sub_pixel_position.round()
			var anim_dir := Vector2(tile_path[0] - current_tile).normalized()
			if not skip_animation:
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


func take_damage(skill: Skill, direction: Vector2) -> void:
	var multiplier: float = _calc_damage_multiplier(direction)

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
	died.emit()
	queue_free()


func process_reactions(effected_unit: Character) -> void:
	for reaction: Skill in reactions:
		if not reaction.processed:
			var reaction_state: ReactionState = reaction.state.new(reaction, self, effected_unit)
			
			if reaction_state.can_use():
				set_state(reaction_state)
				await effected_unit.action_processed
				break


func set_state(state: State) -> void:
	_state_machine.change_state.call_deferred(state)


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

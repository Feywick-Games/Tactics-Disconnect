class_name Character
extends Node2D

signal died
signal target_hit
@warning_ignore("unused_signal")
signal action_processed
@warning_ignore("unused_signal")
signal state_requested(state: State)

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
@export
var init_state: GDScript
@export
var turn_state: GDScript
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

@export
var _evasion: int = 4
var _evasion_modifier: int
var evasion: int:
	get:
		return _evasion + _evasion_modifier
@export
var _accuracy: int = 4
var _accuracy_modifer: int
var accuracy: int:
	get:
		return _accuracy + _accuracy_modifer
		


var health: int
var ready_for_battle := false
var current_tile: Vector2i
var status: Array[StatusEffect]
var attack_state: Combat.AttackState
var item: Item
# TODO remove
var processing_action := false
var processing_reaction := false
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
var hit_chance_label: Label = $HealthBar/HitChanceLabel
@onready
var damage_bar: TextureProgressBar = $HealthBar/DamageBar
@onready
var status_label_manager: StatusLabelManager = $StatusLabelManager
@onready
var sfx_player: AudioStreamPlayer2D = $SfxPlayer

func _ready() -> void:
	sub_pixel_position = global_position
	health_bar.hide()
	EventBus.display_requested.connect(_on_display_requested)
	_state_machine = StateMachine.new(self, init_state.new())
	add_child(_state_machine)


func start_encounter() -> void:
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


func is_hit(hit_chance: float) -> bool:
	return (float(hit_chance) / float(evasion)) > randf()


func drop_weapon() -> void:
	attack_state = Combat.AttackState.BASIC
	item = null
	#TODO play drop animation on skill animator


func process_status_effect(effect: StatusEffect) -> void:
	if effect.status == Combat.Status.HIT:
		health -= round(effect.value * effect.multiplier)
	elif effect.status == Combat.Status.SLOWED:
		_movement_modifier += round(effect.value * effect.multiplier)
	elif effect.status == Combat.Status.DAZED:
		_accuracy_modifer += round(effect.value * effect.multiplier)


func start_turn() -> void:
	health_bar.value = health
	health_bar.show()


func end_turn() -> void:
	GameState.current_level.grid.update_unit_registry(current_tile, self)
	EventBus.turn_ended.emit.call_deferred()
	
	health_bar.hide()
	
	for effect: StatusEffect in status:
		effect.duration -= 1
	
	status = status.filter(func(x: StatusEffect) -> float: return x.duration > 0)
	
	for effect: StatusEffect in status:
		process_status_effect(effect)
	
	EventBus.tiles_highlighted.emit([] as Array[Vector2i], [] as Array[StatusEffect], 0, Vector2i.ZERO, false)


func process_action(tile: Vector2i, attack_range: RangeStruct, state: TurnState) -> State:
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
			EventBus.timer_stopped.emit()
			return skill_state
			
		else:
			EventBus.skill_error_encountered.emit(can_use)


	elif GameState.current_level.get_interactable(tile):
		item = GameState.current_level.take_interactable(tile)
		attack_state = Combat.AttackState.ITEM
		state.interacted = true
	
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


func update_ranges(movement_tiles: RangeStruct, interactable_range: Array[Vector2i]) -> RangeStruct:
	# color tiles differently when attacks overlap with movement 
	var skill: Skill
	var skill_range: RangeStruct
	var attack_atlas_coords: Vector2i
	var overlap_atlas_coords: Vector2i
	var aoe: Array[Vector2i]
	var range_type: Combat.RangeType
	
	if attack_state == Combat.AttackState.BASIC:
		skill = basic_skill
		attack_atlas_coords = Global.RETICLE_ATTACK_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_SPECIAL_2_ATLAS_COORDS
	elif attack_state == Combat.AttackState.SPECIAL:
		skill = special
		attack_atlas_coords = Global.RETICLE_SPECIAL_1_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_CURE_1_ATLAS_COORDS
	elif attack_state == Combat.AttackState.ITEM:
		skill = item
		attack_atlas_coords = Global.RETICLE_ATTACK_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_SPECIAL_2_ATLAS_COORDS
	
	
	skill_range = GameState.current_level.grid.request_range(current_tile, skill.min_range, skill.max_range, skill.range_shape, true, skill.direct)
	aoe = skill.aoe
	range_type = skill.range_type
	
	skill_range.range_tiles.erase(current_tile)
	var skill_aoe_range := RangeStruct.new()
	for range_tile: Vector2i in skill_range.range_tiles:
		for tile_offset in aoe:
			var direction : Vector2 = VectorF.snap_direction(Vector2(range_tile - current_tile).normalized())
			var tile: Vector2i
			var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(direction.angle()).round())
			if range_type == Combat.RangeType.MELEE:
				tile = current_tile + Vector2i(direction) + offset_rotated
			else:
				tile = range_tile + offset_rotated
			var is_valid := GameState.current_level.grid.region.has_point(tile) \
			and not GameState.current_level.grid.is_point_solid_ignore_unit(tile)
			
			if is_valid and not tile in skill_range.range_tiles and not tile in skill_aoe_range.range_tiles:
				skill_aoe_range.range_tiles.append(tile)
	
	
	var skill_move_range := RangeStruct.new()
	
	var overlap_tiles: Array[Vector2i]
	var attack_only_tiles: Array[Vector2i]
	
	for tile in skill_range.range_tiles + skill_aoe_range.range_tiles:
		if tile in movement_tiles.range_tiles:
			overlap_tiles.append(tile)
		else:
			attack_only_tiles.append(tile)
	
	GameState.current_level.reset_map()
	GameState.current_level.draw_range(movement_tiles.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.draw_range(attack_only_tiles, attack_atlas_coords)
	GameState.current_level.draw_range(overlap_tiles, overlap_atlas_coords)
	GameState.current_level.draw_range(interactable_range, Global.RETICLE_INTERACTABLE_ATLAS_COORDS)
	if not movement_tiles.range_tiles.is_empty():
		GameState.current_level.reticle.set_cell(current_tile, 0, Global.RETICLE_MOVE_ALTAS_COORDS)
		GameState.current_level.select_tile(current_tile)
		
	if skill.move_position != Vector2i.ZERO:
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var move_tile: Vector2i  = Vector2i(Vector2(skill.move_position).rotated(Vector2(direction).angle()).round())
			move_tile = current_tile + move_tile
			if (skill.direct and not GameState.current_level.grid.is_point_solid_ignore_unit(move_tile)) \
			or (not skill.direct and not GameState.current_level.grid.is_point_solid(move_tile)):
				skill_move_range.range_tiles.append(move_tile)
		GameState.current_level.draw_range(skill_move_range.range_tiles, overlap_atlas_coords)
	
	
	return skill_range


func process_movement(delta: float, tile_path: Array[Vector2i], animation := "idle") -> Array[Vector2i]:
	if not tile_path.is_empty():
		var path_position :=  GameState.current_level.tile_to_world(tile_path[0])
		var map_position := GameState.current_level.tile_to_world(current_tile)
		if path_position.distance_to(global_position) > SNAP_DISTANCE:
			var dir: Vector2 = (path_position - global_position).normalized()
			sub_pixel_position += dir * Global.PLAYER_SPEED * delta
			print(sub_pixel_position)
			global_position = sub_pixel_position.round()
			var anim_dir := Vector2(tile_path[0] - current_tile).normalized()
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


func take_damage(skill: Skill, direction: Vector2, hit_chance: float, multiplier: float) -> void:
	var hit_connected: bool
	
	if self is Enemy:
		if GameState.battle_timer.value < GameState.battle_timer.max_value * Global.QUICK_MULTIPLIER:
			multiplier *= Global.QUICK_MULTIPLIER
		elif GameState.battle_timer.value > GameState.battle_timer.max_value * Global.SLOW_MULTIPLIER:
			multiplier *= Global.SLOW_MULTIPLIER
	
	if is_equal_approx(direction.normalized().dot(Vector2(facing).normalized()), -1):
		hit_connected = true
		multiplier += Global.BACK_MULTIPLIER
	else:
		hit_connected = is_hit(hit_chance)
	

	if hit_connected:
		for effect: StatusEffect in skill.status_effects:
			effect.multiplier = multiplier
			status.append(effect)
			process_status_effect(effect)
			status_label_manager.add_status_effect(effect)
	else:
		status_label_manager.add_status_effect(null)
	
	health_bar.value = health
	damage_bar.value = health_bar.value
	
	status_label_manager.display_statuses()


func calculate_hit_chance(hit_direction: Vector2i, hit_accuracy : float) -> int:
	if not is_equal_approx(Vector2(hit_direction).normalized().dot(Vector2(facing).normalized()), -1):
		return round((float(hit_accuracy) / float(evasion)) * 100)
	else: 
		return 100



func die() -> void:
	died.emit()
	queue_free()

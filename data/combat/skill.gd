class_name Skill
extends Resource

const DEFAULT_STICKER: Texture2D= preload("res://ui/sticker/_sprite/sticker_basic_attack.png")
const UI_SMALL_DIMENSIONS: Vector2i = Vector2i(20,20)
const UI_LARGE_DIMENSIONS: Vector2i = Vector2i(60,60)
const DEFAULT_UI_SMALL: Texture2D = preload("res://ui/skill_select/_sprite/skill_select_small.png")
const DEFAULT_UI_LARGE: Texture2D = preload("res://ui/skill_select/_sprite/skill_select_large.png")
const DEFAULT_VISUAL_EFFECT_SCENE: PackedScene = preload("res://entity/visual_effect/_packed_scene/strike_visual_effect.tscn")

@export
var ui_small: Texture2D = DEFAULT_UI_SMALL
@export
var ui_large: Texture2D = DEFAULT_UI_LARGE
@export
var name: String
@export_multiline
var flavor_text: String
@export
var character_animation: String = "idle"
@export
var visual_effect_scene: PackedScene = DEFAULT_VISUAL_EFFECT_SCENE
@export
var visual_effect_targets_only := true
@export
var max_range: int = 1
@export
var min_range: int
@export
var move_position: Vector2i = Vector2i.ZERO
@export
var push_position: Vector2i = Vector2i.ZERO
@export
var range_shape: Combat.RangeShape = Combat.RangeShape.DIAMOND
@export
var state: GDScript
@export
var status_effects: Array[StatusEffect]
@export
var aoe: Array[Vector2i] = [Vector2i.ZERO]
@export
var range_type: Combat.RangeType = Combat.RangeType.MELEE
# to pierce
@export
var direct := false
@export
var cast_sfx: AudioStream
@export
var hit_sfx: AudioStream


func _init() -> void:
	resource_local_to_scene = true


func get_hit_damage() -> int:
	var damage_status : Array[StatusEffect] = status_effects.filter(func(x: StatusEffect) -> bool: return true if x.status == Combat.Status.HIT else false)
	if not damage_status.is_empty():
		return damage_status[0].value
	else:
		return 0


func draw_range(attack_range: Array[Vector2i], is_special: bool) -> void:
	if is_special:
		GameState.current_level.reticle.draw_range(attack_range, Global.RETICLE_SPECIAL_ALTAS_COORDS)
	else:
		GameState.current_level.reticle.draw_range(attack_range, Global.RETICLE_ATTACK_ATLAS_COORDS)


func apply_status_effects(actor_status: Array[StatusEffect]) -> void:
	for actor_effect: StatusEffect in actor_status:
		for skill_effect: StatusEffect in status_effects:
			if skill_effect.status == Combat.Status.HIT and actor_effect.status == Combat.Status.DAMAGE:
				skill_effect.value = max(skill_effect.value - actor_effect.status, 0)


func highlight_targets(current_tile: Vector2i, target_tile: Vector2i, attack_range: Array[Vector2i], direction: Vector2) -> void:	
	for tile_offset in aoe:
		var tile: Vector2i
		var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(direction.angle()).round())
		tile = target_tile + offset_rotated
			
		if not tile in attack_range:
			# for aoe "direct/pierce" shouldn't matter
			var is_valid := GameState.current_level.grid.region.has_point(tile) \
			and not GameState.current_level.grid.is_point_solid_ignore_unit(tile)
			
			if not is_valid:
				continue
				
			var atlas_coords: Vector2i = GameState.current_level.reticle.get_cell_atlas_coords(target_tile)
			GameState.current_level.reticle.set_cell(tile, 0, atlas_coords)
			
		GameState.current_level.reticle.select_tile(tile)
	
	if push_position != Vector2i.ZERO:
		var push_range: Array[Vector2i] = []
		var push_tile: Vector2i  = Vector2i(Vector2(push_position).rotated(Vector2(direction).angle()).round())
		push_tile = target_tile + push_tile
		for i in range(1, target_tile.distance_to(push_tile) + 1):
			var tile: Vector2i = target_tile + (Vector2i(direction.round()) * i)
			if GameState.current_level.grid.region.has_point(tile) \
			and GameState.current_level.grid.is_point_solid(tile):
				break
			else:
				push_range.append(tile)
		if not push_range.is_empty():
			GameState.current_level.reticle.draw_range(push_range, Global.RETICLE_SPECIAL_ALTAS_COORDS)
			GameState.current_level.reticle.select_tile(push_range[-1])
	

	if move_position != Vector2i.ZERO:
		var move_tile: Vector2i  = Vector2i(Vector2(move_position).rotated(Vector2(direction).angle()).round())
		move_tile = current_tile + move_tile
		if (direct and not GameState.current_level.grid.is_point_solid_ignore_unit(move_tile)) \
		or (not direct and not GameState.current_level.grid.is_point_solid(move_tile)):
			GameState.current_level.reticle.draw_range([move_tile], Global.RETICLE_MOVE_ALTAS_COORDS)
			GameState.current_level.reticle.select_tile(move_tile)

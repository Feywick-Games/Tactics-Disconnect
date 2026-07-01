class_name Skill
extends Resource

const DEFAULT_STICKER: Texture2D= preload("res://ui/sticker/_sprite/sticker_basic_attack.png")
const UI_SMALL_DIMENSIONS: Vector2i = Vector2i(20,20)
const UI_LARGE_DIMENSIONS: Vector2i = Vector2i(60,60)
const DEFAULT_UI_SMALL: Texture2D = preload("res://ui/skill_select/_sprite/skill_select_small.png")
const DEFAULT_UI_LARGE: Texture2D = preload("res://ui/skill_select/_sprite/skill_select_large.png")

@export
var ui_small: Texture2D = DEFAULT_UI_SMALL
@export
var ui_large: Texture2D = DEFAULT_UI_LARGE
@export
var name: String
@export_multiline
var flavor_text: String
@export
var character_animation: String
@export
var skill_animation: String
@export
var max_range: int = 1
@export
var min_range: int
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
var direct := true
@export
var is_animated := false
@export
var cast_sfx: AudioStream
@export
var hit_sfx: AudioStream


func _init() -> void:
	resource_local_to_scene = true


func is_ready() -> bool:
	return true

func get_hit_damage() -> int:
	var damage_status := status_effects.filter(func(x: StatusEffect) -> bool: return true if x.status == Combat.Status.HIT else false)
	if not damage_status.is_empty():
		return damage_status[0].value
	else:
		return 0

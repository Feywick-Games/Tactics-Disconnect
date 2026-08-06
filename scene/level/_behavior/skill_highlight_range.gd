class_name SkillHighlightRange
extends Node

var tiles: Array[Vector2i]
var status_effects: Array[StatusEffect] 
var direction: Vector2i
var is_ally: bool

func update(tiles_: Array[Vector2i], status_effects_: Array[StatusEffect], direction_: Vector2i, is_ally_: bool) -> void:
	tiles = tiles_
	status_effects = status_effects_
	direction = direction_
	is_ally = is_ally_

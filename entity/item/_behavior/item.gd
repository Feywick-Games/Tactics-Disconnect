class_name Item
extends Skill

const ITEM_STICKER: Texture2D= preload("res://ui/sticker/_sprite/sticker_item.png")

@export
var durability: int = 1
@export
var movement_penalty: int

var min_throw_range: int = 1
var throw_skill: Skill

func is_broken() -> bool:
	return durability <= 0

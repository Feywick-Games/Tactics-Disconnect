class_name StickerLayout
extends HBoxContainer

var _unit: Character

@onready
var _special_sticker: TextureRect = $SpecialSticker


func _ready() -> void:
	hide()


func start_turn(unit: Character) -> void:
	if not visible:
		show()
	
	_special_sticker.hide()
	$SpecialLabel.hide()
	_unit = unit
	if _unit.special:
		_special_sticker.show()
		var special_sticker := AtlasTexture.new()
		special_sticker.atlas = _unit.special.ui_small
		special_sticker.region =  Rect2(Vector2.ZERO, Skill.UI_SMALL_DIMENSIONS)
		custom_minimum_size = Skill.UI_SMALL_DIMENSIONS
		custom_maximum_size = Skill.UI_SMALL_DIMENSIONS
		_special_sticker.texture = special_sticker
		$SpecialLabel.show()
		$SpecialLabel.text = _unit.special.name

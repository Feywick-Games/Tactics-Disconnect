class_name StickerLayout
extends HBoxContainer

var _unit: Character

@onready
var _basic_skill_sticker: TextureRect = $BasicSkillSticker
@onready
var _special_sticker: TextureRect = $SpecialSticker
@onready
var _sticker_highlight: Control = %StickerHighlight
@onready
var _sticker_parent: TextureRect =  _sticker_highlight.get_parent()


func _ready() -> void:
	hide()
	EventBus.turn_started.connect(_on_turn_started)


func _on_turn_started(unit: Character) -> void:
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


#func _process(_delta: float) -> void:
	#if _unit:
		#if _unit.attack_state in [Combat.AttackState.ITEM]:
			#_basic_skill_sticker.texture = _unit.item.sticker
		#else:
			#_basic_skill_sticker.texture = _unit.basic_skill.sticker
			#if _unit.special:
				#_special_sticker.texture = _unit.special.sticker
		#
		#
		#if _unit.attack_state == Combat.AttackState.BASIC:
			#if not _sticker_parent == _basic_skill_sticker:
				#_sticker_parent.remove_child(_sticker_highlight)
				#_basic_skill_sticker.add_child(_sticker_highlight)
				#_sticker_parent = _basic_skill_sticker
		#elif _unit.attack_state == Combat.AttackState.SPECIAL:
			#if not _sticker_parent == _special_sticker:
				#_sticker_parent.remove_child(_sticker_highlight)
				#_special_sticker.add_child(_sticker_highlight)
				#_sticker_parent = _special_sticker
		#elif _unit.attack_state == Combat.AttackState.ITEM:
			#if not _sticker_parent == _special_sticker:
				#_sticker_parent.remove_child(_sticker_highlight)
				#_basic_skill_sticker.add_child(_sticker_highlight)
				#_sticker_parent = _basic_skill_sticker
		#elif _unit.attack_state == Combat.AttackState.SPECIAL:
			#if not _sticker_parent == _special_sticker:
				#_sticker_parent.remove_child(_sticker_highlight)
				#_special_sticker.add_child(_sticker_highlight)
				#_sticker_parent = _special_sticker

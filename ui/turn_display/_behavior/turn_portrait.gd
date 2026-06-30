class_name TurnPortrait
extends Control

@onready
var _small_portrait: Sprite2D = $SmallPortrait
@onready
var _full_portrait: Sprite2D = $FullPortrait
@onready
var _animation_player: AnimationPlayer = $AnimationPlayer
var _character: Character


func _ready() -> void:
	reset_portrait()


func update() -> void:
	if _character.special:
		$SmallPortrait/SpecialIcon.texture = _character.special.ui_small
		$FullPortrait/SpecialIcon.texture = _character.special.ui_small
	else:
		$SmallPortrait/SpecialIcon.hide()
		$FullPortrait/SpecialIcon.hide()


func display_full_portrait() -> void:
	_small_portrait.hide()
	_full_portrait.show()
	
	custom_minimum_size = Vector2(64,64)
	
	if "turn_start" in _animation_player.get_animation_list():
		_animation_player.play("turn_start")


func reset_portrait() -> void:
	_small_portrait.show()
	_full_portrait.hide()
	custom_minimum_size = Vector2(20,20)


func set_up(character: Character) -> void:
	_character = character
	$FullPortrait/Label.text = character.character_name

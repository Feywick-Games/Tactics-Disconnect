class_name UnitSkillList
extends VBoxContainer

@onready
var _character_name_label: Label = %CharacterNameLabel
@onready
var _character_sprite: TextureRect = %CharacterSprite
@onready
var skill_buttons: Array[SkillSelectButton] = [%SkillButton, %SkillButton2, %SkillButton3, %SkillButton4, %SkillButton5]

func _ready() -> void:
	for button: SkillSelectButton in skill_buttons:
		button.skill_selected.connect(_on_skill_selected)
		button.skill_canceled.connect(_on_skill_canceled)


func deal(unit: Ally) -> void:
	_character_name_label.text = unit.character_name
	_character_sprite.texture = unit.small_portrait
	unit.deal_skills()
	
	var skill_hand : Array[Skill] = unit.current_skill_hand
	
	for button : SkillSelectButton in skill_buttons:
		button.unload()
	
	var i: int = 0
	for skill: Skill in skill_hand:
		skill_buttons[i].setup(unit, skill)
		i += 1


func _on_skill_selected(_ally: Ally, _skill: Skill) -> void:
	for button: SkillSelectButton in skill_buttons:
		button.disabled = true
		

func _on_skill_canceled(_ally: Ally, _skill: Skill) -> void:
	for button: SkillSelectButton in skill_buttons:
		button.reset()
		

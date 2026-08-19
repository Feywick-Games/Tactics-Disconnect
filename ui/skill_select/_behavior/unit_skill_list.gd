class_name UnitSkillList
extends VBoxContainer

signal child_focus_entered
signal unit_selected

@onready
var _character_name_label: Label = %CharacterNameLabel
@onready
var unit_button: UnitSelectButton = %UnitButton
@onready
var skill_buttons: Array[SkillSelectButton] = [%SkillButton1, %SkillButton2, %SkillButton3, %SkillButton4]

func _ready() -> void:
	for button: SkillSelectButton in skill_buttons:
		button.skill_selected.connect(_on_skill_selected)
		button.skill_canceled.connect(_on_skill_canceled)
		button.focus_entered.connect(_on_child_focus_entered)
	unit_button.focus_entered.connect(_on_child_focus_entered)
	unit_button.unit_selected.connect(_on_unit_selected)


func _on_unit_selected() -> void:
	pass


func _on_child_focus_entered() -> void:
	child_focus_entered.emit()


func deal(unit: Ally) -> void:
	_character_name_label.text = unit.character_name
	unit.deal_skills()
	
	var skill_hand : Array[Skill] = unit.current_skill_hand
	
	for button : SkillSelectButton in skill_buttons:
		button.unload()
	
	var i: int = 0
	for skill: Skill in skill_hand:
		skill_buttons[i].setup(unit, skill)
		i += 1
	
	unit_button.setup(unit)
	

func _on_skill_selected(_ally: Ally, _skill: Skill) -> void:
	for button: SkillSelectButton in skill_buttons:
		button.disabled = true
		

func _on_skill_canceled(_ally: Ally, _skill: Skill) -> void:
	for button: SkillSelectButton in skill_buttons:
		button.reset()
		

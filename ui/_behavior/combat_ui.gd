class_name CombatUI
extends CanvasLayer

@onready
var _skill_label: Label = %SkillLabel
@onready
var _combat_panel: PanelContainer = $CombatPanel


func _ready() -> void:
	_skill_label.hide()
	_combat_panel.hide()
	EventBus.skills_selected.connect(_on_skills_selected)


func display_skill_text(skill_text: String) -> void:
	_skill_label.show()
	_skill_label.text = skill_text
	await get_tree().create_timer(2).timeout
	_skill_label.hide()


func _on_skills_selected() -> void:
	_combat_panel.show()

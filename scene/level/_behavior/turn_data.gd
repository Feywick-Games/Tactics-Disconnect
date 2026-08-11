class_name TurnData
extends Node

var active_unit: Character
var active_skill_state: SkillState

func _init(unit: Character) -> void:
	active_unit = unit

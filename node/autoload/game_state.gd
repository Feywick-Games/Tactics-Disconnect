extends Node

var battle_timer: BattleTimer
var current_level: Level
var allies: Array[Ally]
@onready
var level_viewport: SubViewportContainer = $"../Game/LevelViewportContainer"

var is_skill_select_ready := false


func _on_ally_died(unit: Character) -> void:
	allies.erase(unit)


func register_ally(unit: Character) -> void:
	allies.append(unit)
	unit.died.connect(_on_ally_died.bind(unit))

extends Node

var battle_timer: BattleTimer
var current_level: Level
@onready
var level_viewport: SubViewportContainer = $"../Game/LevelViewportContainer"

var is_skill_select_ready := false

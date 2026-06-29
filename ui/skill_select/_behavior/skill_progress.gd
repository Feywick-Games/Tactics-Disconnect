class_name SkillProgress
extends ProgressBar

var turns_per_skill_load := 9

@export
var active_material: Material

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_started.connect(_progress_bar_full)
	turns_per_skill_load = GameState.allies.size() * 3
	max_value = turns_per_skill_load
	step = 1


func _progress_bar_full() -> void:
	EventBus.skill_progress_ready.emit()


func _on_turn_started(unit: Character) -> void:
	if unit is Ally:
		value += step

class_name SkillProgress
extends ProgressBar

const FULL_MATERIAL: ShaderMaterial = preload("res://ui/skill_select/_material/skill_select_progress_shader_max.tres")

var turns_per_skill_load := 9

@export
var active_material: Material

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_started.connect(_progress_bar_full)
	EventBus.skills_selected.connect(_on_skills_selected)
	turns_per_skill_load = GameState.allies.size() * 3
	max_value = turns_per_skill_load
	value = -1
	step = 1


func _on_skills_selected() -> void:
	value = 0
	material = null
	GameState.is_skill_select_ready = false


func _progress_bar_full() -> void:
	GameState.is_skill_select_ready = true
	material = FULL_MATERIAL


func _on_turn_started(unit: Character) -> void:
	if unit is Ally:
		value += step
		if value == max_value:
			_progress_bar_full()

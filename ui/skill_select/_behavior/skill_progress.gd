class_name SkillProgress
extends ProgressBar

const FULL_MATERIAL: ShaderMaterial = preload("res://ui/skill_select/_material/skill_select_progress_shader_max.tres")

var turns_per_skill_load := 9
var first_turn := true

@export
var active_material: Material

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_started.connect(_progress_bar_full)
	EventBus.skills_selected.connect(_on_skills_selected)
	turns_per_skill_load = GameState.allies.size() * 3
	max_value = turns_per_skill_load
	value = 0
	step = 1


func _on_skills_selected() -> void:
	material = null
	value = 0
	GameState.is_skill_select_ready = false


func _progress_bar_full() -> void:
	GameState.is_skill_select_ready = true
	material = FULL_MATERIAL


func _on_turn_started(unit: Character) -> void:
	if unit is Ally:
		if not first_turn:
			value += step
		else:
			first_turn = true
		if value == max_value:
			_progress_bar_full()

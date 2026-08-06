class_name SkillProgress
extends ProgressBar

const FULL_MATERIAL: ShaderMaterial = preload("res://ui/skill_select/_material/skill_select_progress_shader_max.tres")

var is_ready := true

@export
var active_material: Material

func _ready() -> void:
	max_value = 2
	value = -1
	step = 1


func reset() -> void:
	material = null
	value = -1
	is_ready = false


func _progress_bar_full() -> void:
	is_ready = true
	material = FULL_MATERIAL


func increment() -> void:
	if value == max_value:
		_progress_bar_full()
	else:
		value += step

	

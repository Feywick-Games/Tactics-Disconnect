class_name SkillProgress
extends TextureProgressBar

var is_ready := true

var shader_material: ShaderMaterial = material as ShaderMaterial

func _ready() -> void:
	max_value = 3
	value = 0
	step = 1


func reset() -> void:
	value = 0
	is_ready = false


func _progress_bar_full() -> void:
	is_ready = true


func increment() -> void:
	if value == max_value:
		_progress_bar_full()
	else:
		value += step
		shader_material.set_shader_parameter("value", value)

	

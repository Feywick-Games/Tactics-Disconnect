class_name CombatUI
extends CanvasLayer

@export
var error_audio_stream: AudioStream

var _error_queued: bool = false
var _error_code_timer: SceneTreeTimer

@onready
var _skill_label: Label = %SkillLabel
@onready
var _combat_panel: Control = $CombatPanel
@onready
var _audio_stream_player: AudioStreamPlayer

func _ready() -> void:
	show()
	_skill_label.hide()
	_combat_panel.hide()
	EventBus.skills_selected.connect(_on_skills_selected)
	EventBus.skill_error_encountered.connect(_display_skill_error_code)


func _display_skill_error_code(code: Global.SkillErrorCode) -> void:
	_error_queued = true
	
	if _error_code_timer:
		_error_code_timer.timeout.disconnect(_on_error_code_timer_expired)
	
	match code:
		Global.SkillErrorCode.NO_TARGET:
			_skill_label.show()
			_skill_label.text = "No Target Found!"
		Global.SkillErrorCode.MOVE_BLOCKED:
			_skill_label.show()
			_skill_label.text = "Can't Move To Tile!"
			
	if error_audio_stream:
		_audio_stream_player.stream = error_audio_stream
		_audio_stream_player.play()
	
	_error_code_timer = get_tree().create_timer(1)
	_error_code_timer.timeout.connect(_on_error_code_timer_expired)


func _on_error_code_timer_expired() -> void:
	_skill_label.hide()



func display_skill_text(skill_text: String) -> void:
	if _error_code_timer:
		_error_code_timer.timeout.disconnect(_on_error_code_timer_expired)
	
	_skill_label.show()
	_skill_label.text = skill_text
	await get_tree().create_timer(2).timeout
	_skill_label.hide()


func _on_skills_selected() -> void:
	_combat_panel.show()

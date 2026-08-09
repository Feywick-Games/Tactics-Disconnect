class_name CombatUI
extends CanvasLayer

@export
var error_audio_stream: AudioStream

var _error_queued: bool = false
var _text_timer: SceneTreeTimer

@onready
var _skill_label: Label = %SkillLabel
@onready
var combat_panel: Control = $CombatPanel
@onready
var _audio_stream_player: AudioStreamPlayer
@onready
var turn_display : TurnDisplay = %TurnDisplay
@onready
var skill_progress : SkillProgress = %SkillProgress
@onready
var skill_select : SkillSelect = %SkillSelect
@onready
var battle_timer: BattleTimer = %BattleTimer
@onready
var push_progress: PushProgress = %PushProgress
@onready
var sticker_layout: StickerLayout = %StickerLayout
@onready
var reaction_qte_manager: ReactionQteManager = %ReactionQteManager
@onready
var range_challege: RangeChallenge = %RangeChallenge


func _ready() -> void:
	show()
	_skill_label.hide()
	combat_panel.hide()
	skill_select.skills_selected.connect(_on_skills_selected)
	skill_select.skills_selected.connect(skill_progress.reset)


func display_skill_error_code(code: Global.SkillErrorCode) -> void:
	_error_queued = true
	
	if _text_timer:
		_text_timer.timeout.disconnect(_on_text_timer_expired)
	
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
	
	_text_timer = get_tree().create_timer(1)
	_text_timer.timeout.connect(_on_text_timer_expired)


func _on_text_timer_expired() -> void:
	_skill_label.text = ""
	_skill_label.hide()



func display_skill_text(skill_text: String) -> void:
	if _text_timer:
		_text_timer.timeout.disconnect(_on_text_timer_expired)
	
	_skill_label.show()
	_skill_label.text = skill_text
	_text_timer = get_tree().create_timer(1)
	_text_timer.timeout.connect(_on_text_timer_expired)


func _on_skills_selected() -> void:
	combat_panel.show()


func open_skill_select(allies: Array[Ally]) -> void:
	skill_select.open(allies)
	combat_panel.hide()


func start_turn(units: Array[Character]) -> void:
	turn_display.start_turn(units)
	battle_timer.start(units[0])
	sticker_layout.start_turn(units[0])

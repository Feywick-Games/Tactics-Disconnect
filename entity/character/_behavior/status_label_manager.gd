class_name StatusLabelManager
extends Control

signal statuses_displayed

@export
var miss_color: Color = "#70e0d5"
@export
var miss_outline_color: Color = "#1e6485"
@export
var damage_color: Color = "#f7f7f5"
@export
var damage_outline_color: Color = "#0c090d"
@export
var stun_color: Color = "#de9b54"

@onready
var animator: AnimationPlayer = $LabelAnimator
@onready
var status_label : Label = $StatusLabel

var _started_animations: int
var _queued_statuses: Array[StatusEffect]
var _completed_animations: int
var _damage_value: int


func _ready() -> void:
	hide()
	animator.animation_finished.connect(_on_animation_completed)


func display_statuses() -> void:
	for i in range(_queued_statuses.size()):
		_started_animations += 1
		_play_status_effect(_queued_statuses[i])
	animator.play()


func _play_status_effect(effect: StatusEffect) -> void:
	if not effect:
		animator.queue("miss")
	elif effect.status == Combat.Status.HIT:
		_damage_value = floor(effect.value * effect.multiplier)
		animator.queue("hit")
	

	
func add_status_effect(effect: StatusEffect) -> void:
	if not effect or effect.status in [Combat.Status.HIT]:
		_queued_statuses.append(effect)
	
	
func _on_animation_completed(_anim: String) -> void:
	_completed_animations += 1 
	if _completed_animations == _started_animations:
		_queued_statuses.clear()
		_started_animations = 0
		_completed_animations = 0
		_damage_value = 0
		statuses_displayed.emit()
		hide()


func set_damage_value() -> void:
	status_label.text = str(_damage_value)

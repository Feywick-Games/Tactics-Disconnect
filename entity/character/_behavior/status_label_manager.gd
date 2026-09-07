class_name StatusLabelManager
extends Control

@export
var multiplier_sound: AudioStream
@export
var demultiplier_sound: AudioStream

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
@onready
var sfx_player: SfxPlayer = $SfxPlayer

var _started_animations: int
var _queued_statuses: Array[StatusEffect]
var _completed_animations: int
var _damage_value: int
var _queued_sounds: Array[AudioStream]

var playing := false


func _ready() -> void:
	hide()
	animator.animation_finished.connect(_on_animation_completed)


func display_statuses(_rear: bool) -> void:
	for i in range(_queued_statuses.size()):
		_started_animations += 1
		_play_status_effect(_queued_statuses[i])
	if animator.current_animation == "":
		_on_animation_completed("")
	playing = true
	

func _play_status_effect(effect: StatusEffect) -> void:
	if effect.status == Combat.Status.HIT:
		_damage_value = effect.value
		animator.queue("hit")
	elif effect.status == Combat.Status.MOVEMENT:
		if effect.value < 0:
			animator.queue("move_down")
		else:
			animator.queue("move_up")
	elif effect.status == Combat.Status.DAMAGE:
		if effect.value < 0:
			animator.queue("dmg_down")
		else:
			animator.queue("dmg_up")
	animator.speed_scale = animator.get_queue().size() + 1


func preview(_effect: StatusEffect) -> void:
	# show preview of effect without animation
	pass


func add_status_effect(effect: StatusEffect) -> void:
	if effect.status in [Combat.Status.HIT, Combat.Status.MOVEMENT, Combat.Status.DAMAGE]:
		if not effect.status == Combat.Status.HIT:
			_queued_statuses.append(effect)
		else:
			_queued_statuses.insert(0, effect)
	
	
func _on_animation_completed(_anim: String) -> void:
	_completed_animations += 1
	play_queued_sound()
	if _completed_animations == _started_animations or _started_animations == 0:
		_queued_statuses.clear()
		_started_animations = 0
		_completed_animations = 0
		_damage_value = 0
		playing = false
		hide()


func play_queued_sound() -> void:
	if not _queued_sounds.is_empty():
		await get_tree().create_timer(.5 / animator.speed_scale).timeout
		var sfx: AudioStream = _queued_sounds.pop_back()
		sfx_player.stream = sfx
		sfx_player.play_sfx()


func set_damage_value() -> void:
	status_label.text = str(_damage_value)
	
	
func play_actor_status(anim: String, is_multiplier := true) -> void:
	animator.queue(anim)
	var anim_count : int = animator.get_queue().size() + 1
	animator.speed_scale = anim_count
	if is_multiplier:
		_queued_sounds.append(multiplier_sound)
	else:
		_queued_sounds.append(demultiplier_sound)
	if not sfx_player.playing:
		play_queued_sound()

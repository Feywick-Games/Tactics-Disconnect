class_name PushProgress
extends HBoxContainer

const PUSH_PROGRESS_SCALE: float = 5

var _running := false
var _push_progress_duration : float = 4
var _time_progressing : float = 0

@onready
var _push_progress_bar: TextureProgressBar = $VBoxContainer/PushProgressBar
@onready
var _push_timer_bar: TextureProgressBar = $VBoxContainer/PushProgressTimer

func _ready() -> void:
	hide()
	EventBus.push_progress_requested.connect(_on_push_progress_requested)
	

func _on_push_progress_requested() -> void:
	show()
	_running = true
	_push_timer_bar.value = 0
	_push_timer_bar.max_value = _push_progress_duration
	_push_progress_bar.value = 0
	

func _process(delta: float) -> void:
	if _running:
		if Input.is_action_just_pressed("accept"):
			_push_progress_bar.value += PUSH_PROGRESS_SCALE
			
		_time_progressing += delta
		
		if _time_progressing > _push_progress_duration \
		or _push_progress_bar.value >= _push_progress_bar.max_value:
			_end()
			
		_push_timer_bar.value = _time_progressing


func _end() -> void:
	_running = false
	EventBus.push_progress_completed.emit(_push_progress_bar.value / _push_progress_bar.max_value)
	hide()

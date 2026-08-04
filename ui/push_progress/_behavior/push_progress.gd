class_name PushProgress
extends HBoxContainer

const PUSH_TIMER_SCALE: float = 1
const PUSH_PROGRESS_SCALE: float = 6

signal completed(pct: int)

var _running := false
var _time_progressing : float = 0

@onready
var _push_progress_bar: TextureProgressBar = $VBoxContainer/PushProgressBar
@onready
var _push_timer_bar: TextureProgressBar = $VBoxContainer/PushProgressTimer

func _ready() -> void:
	hide()

func start(distance: int) -> void:
	show()
	_running = true
	_push_timer_bar.value = 0
	_push_timer_bar.max_value = distance * PUSH_TIMER_SCALE
	_push_progress_bar.value = 0
	_push_progress_bar.max_value = distance * PUSH_PROGRESS_SCALE
	

func _process(delta: float) -> void:
	if _running:
		if Input.is_action_just_pressed("accept"):
			_push_progress_bar.value += 1
			
		_time_progressing += delta
		
		if _time_progressing > _push_timer_bar.max_value \
		or _push_progress_bar.value >= _push_progress_bar.max_value:
			_end()
			
		_push_timer_bar.value = _time_progressing


func _end() -> void:
	_running = false
	completed.emit(_push_progress_bar.value / _push_progress_bar.max_value)
	hide()

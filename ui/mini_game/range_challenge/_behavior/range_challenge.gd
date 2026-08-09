class_name RangeChallenge
extends MiniGame

const MAX_DISTANCE: float = 12
const MIN_RANGE_WIDTH: float = .1
const MAX_RANGE_WIDTH: float = .5
const SLIDER_SPEED_SCALE: float = .75
const MAX_TIME: float = 3.0

@export
var success := false

var _slider_speed: float
var _increasing := true
var _tapped := false
var _min_success_value : float
var _max_success_value : float
var _running := false

@onready
var _range_goal: TextureProgressBar = $HBoxContainer/VBoxContainer/RangeGoal
@onready
var _reticle: HSlider = $HBoxContainer/VBoxContainer/RangeGoal/Reticle
@onready
var _timer_bar: TextureProgressBar = $HBoxContainer/VBoxContainer/TimerBar


func _ready() -> void:
	hide()
	_reticle.max_value = _reticle.size.x
	_range_goal.max_value = _reticle.max_value
	_slider_speed = _reticle.max_value * SLIDER_SPEED_SCALE


func start(from: Vector2i, to: Vector2i) -> void:
	show()
	var distance: float = from.distance_to(to)
	var challenge_level : float = min(distance / MAX_DISTANCE,1)
	_range_goal.step = 1
	_range_goal.value = lerp(MIN_RANGE_WIDTH*_reticle.max_value, MAX_RANGE_WIDTH*_reticle.max_value, challenge_level)
	_min_success_value = (_range_goal.max_value * .5) - (_range_goal.value / 2.0)
	_max_success_value = (_range_goal.max_value * .5) + (_range_goal.value / 2.0)
	completed = false
	_reticle.value = 0
	_increasing = true
	_timer_bar.value = 0
	_timer_bar.step = .001
	_timer_bar.max_value = MAX_TIME
	_running = true


func _end() -> void:
	completed = true
	_running = false
	if _tapped and _reticle.value <= _max_success_value and _reticle.value >= _min_success_value:
		success = true
	else:
		success = false
	hide()


func _process(delta: float) -> void:
	if _running:
		_update_reticle(delta)
		_timer_bar.value += delta
		
		if _timer_bar.value >= _timer_bar.max_value:
			_end()
	if Input.is_action_just_pressed("accept") and _running:
		_end()


func _update_reticle(delta: float) -> void:
	var move_dist: float = delta * _slider_speed
	
	if _increasing:
		if _reticle.value + move_dist >= _reticle.max_value:
			_increasing = false
		else:
			_reticle.value += move_dist
	if not _increasing:
		if _reticle.value - move_dist <= _reticle.min_value:
			_increasing = true
			_reticle.value += move_dist
		else:
			_reticle.value -= move_dist

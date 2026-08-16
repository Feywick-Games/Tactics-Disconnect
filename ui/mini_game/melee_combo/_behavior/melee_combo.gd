class_name MeleeCombo
extends MiniGame

const MAX_TIME := 3
const MAX_AOE_SIZE := 5

var game_pad_indicator_scene: PackedScene = load("res://ui/mini_game/melee_combo/_packed_scene/game_pad_indicator.tscn")
var action_names:Array[String] = [
	"accept", "cancel", 
	"move_up", "move_down", 
	"move_left", "move_right"
]
var _current_button: GamePadIndicator
var _buttons: Array[GamePadIndicator]
var _running: bool = false
var _combo_length: int 

@onready
var _button_container: HBoxContainer = $VBoxContainer/HBoxContainer
@onready
var _timer_bar: TextureProgressBar = $VBoxContainer/TimerBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child: Node in _button_container.get_children():
		child.free()
	hide()


func _end() -> void:
	_running = false
	await get_tree().create_timer(1).timeout
	completed = true
	value = 1 - (float(_buttons.size()) / float(_combo_length) * .5)
	if _buttons.is_empty():
		success = true
	
	for child: Node in _button_container.get_children():
		child.free()
	hide()


func start(aoe_size: int) -> void:
	show()
	var button_cnt: int = min(aoe_size, MAX_AOE_SIZE)
	for i in range(button_cnt):
		var btn: GamePadIndicator = game_pad_indicator_scene.instantiate()
		var action: String = action_names.pick_random()
		_button_container.add_child(btn)
		btn.present(action)
		_buttons.append(btn)
	_get_next_button()
	completed = false
	_running = true
	_combo_length = button_cnt
	_timer_bar.max_value = MAX_TIME
	_timer_bar.value = 0
	_timer_bar.step = .001


func _process(delta: float) -> void:
	if _running:
		_timer_bar.value += delta
		
		if _timer_bar.value >= _timer_bar.max_value:
			_end()
			return
		
		_check_button_input()


func _check_button_input() -> void:
	var action: String
	if Input.is_action_just_pressed("accept"):
		action = "accept"
	elif Input.is_action_just_pressed("cancel"):
		action = "cancel"
	elif Input.is_action_just_pressed("move_left"):
		action = "move_left"
	elif Input.is_action_just_pressed("move_right"):
		action = "move_right"
	elif Input.is_action_just_pressed("move_up"):
		action = "move_up"
	elif Input.is_action_just_pressed("move_down"):
		action = "move_down"
		
	if action == _current_button.current_action:
		_current_button.present(action, true, true)
		_current_button.animator.queue("explode_highlighted_pressed")
		if not _buttons.is_empty():
			_get_next_button()
		else:
			_end()
		



func _get_next_button() -> void:
	_current_button = _buttons.pop_front()
	_current_button.present(_current_button.current_action, false, true)

class_name ReactionQteManager
extends Control

signal reacted(success: bool)

const TIME_STEP: float = .001

var success_count: int

var _reaction_qte_scene: PackedScene = load("res://ui/reaction_qte/_packed_scene/reaction_qte.tscn")
var _qtes: Array[TextureProgressBar]
var _current_qte: TextureProgressBar
var _max_time: float
var _current_qte_anim_player: AnimationPlayer
var _tapped := false
var _exploding := false
var _time_passed: float

func _ready() -> void:
	hide()
	
	for child: Node in get_children():
		child.free()


func dispatch_qtes(screen_position: Vector2, is_above: bool, buffer_time: float) -> void:
	success_count = 0
	_max_time = buffer_time
	_tapped = false
	_time_passed = 0
	show()
	var qte : Control = _reaction_qte_scene.instantiate()
	qte.global_position = screen_position
	
	if not is_above:
		qte.global_position.y += 15
	else:
		qte.global_position.y -= 40
	
	_qtes.append(qte)
	

func _process(delta: float) -> void:
	if not _qtes.is_empty() and not _current_qte:
		_spawn_qte()
	elif _current_qte:
		_process_current_qte(delta)
	elif visible:
		hide()
	if Input.is_action_just_pressed("accept") and not _tapped:
		_tapped = true


func _spawn_qte() -> void:
	_current_qte = _qtes.pop_front()
	add_child(_current_qte)
	_current_qte.max_value = _max_time - _time_passed
	_current_qte.value = 0
	_current_qte.step = TIME_STEP
	_current_qte_anim_player = _current_qte.get_node("AnimationPlayer")
	_tapped = false
	_exploding = false


func _process_current_qte(delta: float) -> void:
	if _current_qte.value < _max_time and not _tapped:
		_time_passed += delta
		_current_qte.value = _time_passed
	elif _current_qte.value >= _max_time and not _tapped and not _exploding:
		_current_qte_anim_player.play("failure")
		_exploding = true
		reacted.emit(false)
	elif _tapped and not _exploding:
		_current_qte_anim_player.play("explode")
		_exploding = true
		reacted.emit(true)
	elif _exploding and not _current_qte_anim_player.is_playing():
		_current_qte.queue_free()
		_current_qte = null

class_name ReactionQte
extends Control

signal processed

@onready
var animator: AnimationPlayer = $AnimationPlayer
var _react_callables: Array[Callable]
var _succeeded := false


func _ready() -> void:
	hide()


func setup(spawn_signal: Signal, fail_signal: Signal, react_callables: Array[Callable]) -> void:
	spawn_signal.connect(show)
	fail_signal.connect(fail)
	_react_callables = react_callables 


func highlight() -> void:
	animator.play("highlighted")


func explode() -> void:
	for react_call: Callable in _react_callables:
		if is_instance_valid(react_call.get_object()):
			react_call.call(true)
		else:
			printerr("?")
	animator.play("explode")
	animator.animation_finished.connect(queue_free.unbind(1))
	processed.emit()
	_succeeded = true


func fail() -> void:
	if not _succeeded:
		for react_call: Callable in _react_callables:
			react_call.call(false)
		animator.play("failure") 
		animator.animation_finished.connect(queue_free.unbind(1))
		processed.emit()

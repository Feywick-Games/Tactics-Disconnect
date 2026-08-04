class_name StateMachine
extends Node

var _current_state : State
var state_owner : Node

func _init(state_owner_ : Node, init_state : State) -> void:
	self.state_owner = state_owner_
	_current_state = init_state
	_current_state.state_machine = self
	_current_state.enter()


func _process(delta: float) -> void:
	var next_state := _current_state.update(delta)
	if next_state:
		change_state(next_state)


func _physics_process(delta: float) -> void:
	var next_state := _current_state.physics_update(delta)
	if next_state:
		change_state(next_state)


func _unhandled_input(event: InputEvent) -> void:
	var next_state := _current_state.unhandled_input(event)
	if next_state:
		change_state(next_state)


func _input(event: InputEvent) -> void:
	var next_state := _current_state.unhandled_input(event)
	if next_state:
		change_state(next_state)


func change_state(state : State) -> void:
	_current_state.exit()
	for connection in _current_state.get_incoming_connections():
		connection["signal"].disconnect(connection["callable"])
	
	state.state_machine = self
	state.enter()
	_current_state = state

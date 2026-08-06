class_name StateMachine
extends Node

var current_state : State
var state_owner : Node

func _init(state_owner_ : Node, init_state : State) -> void:
	self.state_owner = state_owner_
	current_state = init_state
	current_state.state_machine = self
	current_state.enter()


func _process(delta: float) -> void:
	var next_state := current_state.update(delta)
	if next_state:
		change_state(next_state)


func _physics_process(delta: float) -> void:
	var next_state := current_state.physics_update(delta)
	if next_state:
		change_state(next_state)


func _unhandled_input(event: InputEvent) -> void:
	var next_state := current_state.unhandled_input(event)
	if next_state:
		change_state(next_state)


func _input(event: InputEvent) -> void:
	var next_state := current_state.unhandled_input(event)
	if next_state:
		change_state(next_state)


func change_state(state : State) -> void:
	current_state.exit()
	for connection in current_state.get_incoming_connections():
		connection["signal"].disconnect(connection["callable"])
	
	state.state_machine = self
	state.enter()
	current_state = state

class_name AllyRoamState
extends State

var _ally: Ally
var _encounter_starting := false

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	EventBus.encounter_started.connect(_on_encounter_started)


func update(_delta: float) -> State:
	if _encounter_starting:
		return CharacterCombatBeginState.new()

	return

func _on_encounter_started() -> void:
	_encounter_starting = true

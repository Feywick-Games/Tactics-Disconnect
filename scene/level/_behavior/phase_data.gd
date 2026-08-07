class_name PhaseData
extends RefCounted

enum Event {
	IMPACT,
	COLLIDED
}

var targets: Array[Character]
var damage_states: Array[DamageState]
var damage_states_processed: int
var events: Array[Event]
var skill_error: Global.SkillErrorCode

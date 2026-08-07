class_name DamageState
extends State

var _skill: Skill
var _direction: Vector2
var _damage_multiplier: float
var _character: Character
var _damage_data: PhaseData

func _init(skill: Skill, direction: Vector2, turn_data: PhaseData, multiplier: float = 1) -> void:
	_skill = skill
	_direction = direction
	_damage_multiplier = multiplier
	_damage_data = turn_data


func enter() -> void:
	super.enter()
	_character = state_machine.state_owner as Character
	_character.health_bar.show()
	_character.take_damage(_skill, _direction, _damage_multiplier)


func update(delta: float) -> State:
	if not _character.status_label_manager.playing:
		return CharacterIdleState.new()
	
	return super.update(delta)


func exit() -> void:
	super.exit()
	_damage_data.damage_states_processed += 1
	_character.health_bar.hide()
	if _character.health <= 0:
		_character.die()

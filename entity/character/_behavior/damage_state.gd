class_name DamageState
extends State

var _skill: Skill
var _direction: Vector2
var _hit_signal: Signal
var _request_reaction: bool
var _exiting := false
var _hit := false
var _damage_taken := false
var _damage_multiplier: float
var _character: Character

func _init(skill: Skill, direction: Vector2, hit_signal: Signal, multiplier: float = 1, request_reaction:=true) -> void:
	_skill = skill
	_direction = direction
	_hit_signal = hit_signal
	_request_reaction = request_reaction
	_damage_multiplier = multiplier


func enter() -> void:
	super.enter()
	_character = state_machine.state_owner as Character
	_hit_signal.connect(_on_hit)
	for reaction: Reaction in _character.reactions:
		reaction.processed = false
	_character.health_bar.show()
	_character.status_label_manager.statuses_displayed.connect(_on_statuses_displayed)


func _on_statuses_displayed() -> void:
	_character.health_bar.hide()
	if _character.health <= 0:
		_character.die()
	_exiting = true


func _on_hit() -> void:
	_hit = true


func update(delta: float) -> State:
	if _hit and not _damage_taken:
		_character.take_damage(_skill, _direction, _damage_multiplier)
		_damage_taken = true
		_hit = false
	if _exiting:
		return CharacterIdleState.new()
	
	return super.update(delta)


func exit() -> void:
	super.exit()
	_character.action_processed.emit()

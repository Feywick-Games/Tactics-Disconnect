class_name DamageState
extends CharacterCombatIdleState

var _skill: Skill
var _direction: Vector2
var _hit_chance: float
var _hit_signal: Signal
var _multiplier: float
var _request_reaction: bool
var _exiting := false
var _hit := false

func _init(skill: Skill, direction: Vector2, hit_chance: float, hit_signal: Signal, multiplier: float = 1, request_reaction:=true) -> void:
	_skill = skill
	_direction = direction
	_hit_chance = hit_chance
	_hit_signal = hit_signal
	_multiplier = multiplier
	_request_reaction = request_reaction
	_hit_signal.connect(_on_hit)


func enter() -> void:
	super.enter()
	_character.health_bar.show()
	_character.processing_action = true
	_character.reacting = false
	_character.status_label_manager.statuses_displayed.connect(_on_statuses_displayed)


func _on_statuses_displayed() -> void:
	_character.health_bar.hide()
	_character.processing_action = false
	if _character.health <= 0:
		_character.die()
	if _request_reaction:
		EventBus.reaction_requested.emit(_character)
	_exiting = true


func _on_hit() -> void:
	_hit = true


func update(delta: float) -> State:
	var parent_state: State = super.update(delta)
	if parent_state:
		return parent_state
	
	if _hit and not _damage_taken:
		_character.take_damage(_skill, _direction, _hit_chance, _multiplier)
		_damage_taken = true
		_hit = false
	if _exiting and not _character.reacting:
		return CharacterCombatIdleState.new()
	return super.update(delta)

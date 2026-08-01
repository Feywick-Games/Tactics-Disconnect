class_name ReactionState
extends State

var _character: Character
var _reaction: Reaction
var _target: Character
var _exiting := false

func enter() -> void:
	GameState.combat_ui.display_skill_text(_reaction.name)


func _init(reaction: Skill, character: Character, target: Character) -> void:
	_reaction = reaction
	_character = character
	_target = target


func update(_delta: float) -> State:
	if not is_instance_valid(_target):
		return CharacterCombatIdleState.new()
	
	if _exiting:
		return CharacterCombatIdleState.new()
	return


func exit() -> void:
	_character.action_processed.emit()
	_reaction.processed = true


func can_use() -> bool:
	return false

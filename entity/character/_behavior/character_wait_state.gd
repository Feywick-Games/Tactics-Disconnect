class_name CharacterWaitState
extends State

var _character: Character
var _skill_highlight_range: SkillHighlightRange

func _init(highlight_range: SkillHighlightRange) -> void:
	_skill_highlight_range = highlight_range


func enter() -> void:
	_character = state_machine.state_owner as Character
	# TODO: Replace with combat idle
	if _character.is_animated:
		_character.animator.play_directional("idle", Vector2.ZERO)
	_character.health_bar.hide()
	for reaction: Reaction in _character.reactions:
		reaction.processed = false
	_character.clear_expired_statuses()




func update(_delta : float) -> State:
	if not _character.current_tile in _skill_highlight_range.tiles and _character.health_bar.visible:
		_character.health_bar.hide()
	_character.display_modified_status(_skill_highlight_range.tiles, _skill_highlight_range.status_effects, _skill_highlight_range.direction)
	return


func exit() -> void:
	_character.health_bar.hide()
	_character.highlight(false)

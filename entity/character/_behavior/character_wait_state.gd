class_name CharacterWaitState
extends State

var _character: Character
var _highlighted_tiles: Array[Vector2i]
var _highlighted_status_effects: Array[StatusEffect] 
var _highlighted_direction: Vector2i
var _highlighter_is_ally: bool

func _init(highlight_signal: Signal) -> void:
	highlight_signal.connect(_on_tiles_highlighted)


func enter() -> void:
	_character = state_machine.state_owner as Character
	# TODO: Replace with combat idle
	if _character.is_animated:
		_character.animator.play_directional("idle", Vector2.ZERO)
	_character.health_bar.hide()
	for reaction: Reaction in _character.reactions:
		reaction.processed = false
	_character.clear_expired_statuses()


func _on_tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], direction: Vector2i, is_ally: bool) -> void:
	_highlighted_tiles = tiles
	_highlighted_status_effects = status_effects
	_highlighted_direction = direction
	_highlighter_is_ally = is_ally
	if not _character.current_tile in _highlighted_tiles and _character.health_bar.visible:
		_character.health_bar.hide()


func update(_delta : float) -> State:
	_character.display_modified_status(_highlighted_tiles, _highlighted_status_effects, _highlighted_direction)
	return


func exit() -> void:
	_character.health_bar.hide()
	_character.highlight(false)

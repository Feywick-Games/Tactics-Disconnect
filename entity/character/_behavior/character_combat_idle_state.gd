class_name CharacterCombatIdleState
extends State

var _character: Character
var _encounter_ended := false
var _turn_started := false
var _highlighted_tiles: Array[Vector2i]
var _highlighted_accuracy: int
var _highlighted_status_effects: Array[StatusEffect] 
var _highlighted_direction: Vector2i
var _highlighter_is_ally: bool
var _damage_taken := false
var _reaction_state: ReactionState
var _is_processing := false
var _requested_state: State

func enter() -> void:
	_character = state_machine.state_owner as Character
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)
	EventBus.tiles_highlighted.connect(_on_tiles_highlighted)
	EventBus.reaction_requested.connect(_on_reaction_requested)
	_character.state_requested.connect(_on_state_requested)
	if _character.is_animated:
		_character.animator.play_directional("combat_idle", Vector2.ZERO)


func _on_state_requested(state: State) -> void:
	_requested_state = state


func _on_reaction_requested(unit: Character) -> void:
	if unit.processing_action:
		return
	
	for reaction: Skill in _character.reactions:
		if not reaction.processed:
			var reaction_state: ReactionState = reaction.state.new(reaction, _character, unit)
			
			if reaction_state.can_use():
				_reaction_state = reaction_state
				unit.reacting = true
				break


func _on_encounter_ended() -> void:
	_encounter_ended = true


func _on_turn_started(unit: Character) -> void:
	if unit == _character:
		_turn_started = true
	_damage_taken = false
	if _character.health_bar.visible:
		_character.health_bar.hide()
	for reaction: Reaction in _character.reactions:
		reaction.processed = false



func _on_tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], 
accuracy: int, direction: Vector2i, is_ally: bool) -> void:
	_highlighted_tiles = tiles
	_highlighted_accuracy = accuracy
	_highlighted_status_effects = status_effects
	_highlighted_direction = direction
	_highlighter_is_ally = is_ally
	if not _character.current_tile in _highlighted_tiles and _character.health_bar.visible:
		_character.health_bar.hide()

# TODO move to own state
func _display_health() -> void:
	if _character.current_tile in _highlighted_tiles:
		_character.health_bar.show()
		_character.hit_chance_label.show()
		(_character.sprite.material as ShaderMaterial).set_shader_parameter("highlighted", true)
	elif _character.hit_chance_label.visible or _character.damage_bar.value != _character.health_bar.value:
		_character.hit_chance_label.hide()
		(_character.sprite.material as ShaderMaterial).set_shader_parameter("highlighted", false)
	if not _damage_taken:
		var multiplier: float = 1
		if _highlighter_is_ally:
			if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
				multiplier = 1.5
			elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
				multiplier = .5
			
		if is_equal_approx(Vector2(_highlighted_direction).normalized().dot(Vector2(_character.facing).normalized()), -1) and _character.facing != Vector2i.ZERO:
			multiplier += .5
		for effect: StatusEffect in _highlighted_status_effects:
			if effect.status == Combat.Status.HIT:
				_character.health_bar.value = _character.health - (effect.value * multiplier)
		
		var hit_chance: int = _character.calculate_hit_chance(_highlighted_direction, _highlighted_accuracy)

		_character.hit_chance_label.text = str(hit_chance) + "%" 
		
		var hit_chance_color: Color
		if hit_chance <= 50:
			hit_chance_color = Color.FIREBRICK
		elif hit_chance <= 75:
			hit_chance_color = Color.ORANGE_RED
		else:
			hit_chance_color = Color.WHITE
		
		_character.hit_chance_label.add_theme_color_override("font_color", hit_chance_color)

	

func update(_delta: float) -> State:
	if _encounter_ended:
		_character.end_encounter()
		return _character.init_state.new()
	elif _turn_started:
		return _character.turn_state.new()
	elif _requested_state:
		return _requested_state
	elif _reaction_state:
		return _reaction_state
	elif _character.processing_action and not _is_processing:
		_is_processing = true
	elif not _character.processing_action and _is_processing:
		_is_processing = false
		if not _character.reacting:
			_character.action_processed.emit() 
	
	_display_health()
		
	return


func exit() -> void:
	_character.health_bar.hide()
	_character.hit_chance_label.hide()

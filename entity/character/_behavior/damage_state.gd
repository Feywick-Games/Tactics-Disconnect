class_name DamageState
extends State

var _skill: Skill
var _direction: Vector2
var _damage_multiplier: float
var _character: Character
var _damage_taken: bool
var _hit := false

func _init(skill: Skill, direction: Vector2, hit_signal: Signal, multiplier: float = 1, ignore_signal := false) -> void:
	_skill = skill
	_direction = direction
	_damage_multiplier = multiplier
	if not ignore_signal:
		hit_signal.connect(_on_hit)
	else:
		_hit = true

func enter() -> void:
	super.enter()
	_character = state_machine.state_owner as Character
	_character.health_bar.show()


func update(delta: float) -> State:
	if _hit and not _damage_taken:
		_character.take_damage(_skill, _direction, _damage_multiplier)
		_damage_taken = true
	elif not _character.status_label_manager.playing and _damage_taken:
		return CharacterIdleState.new()
	
	return super.update(delta)


func _on_hit() -> void:
	_hit = true


func exit() -> void:
	super.exit()
	if _character.health <= 0:
		_character.die()

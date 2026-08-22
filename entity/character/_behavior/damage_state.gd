class_name DamageState
extends State

var _skill: Skill
var _direction: Vector2
var _character: Character
var _damage_taken: bool
var _hit := false
var _ignore_time_multi := false

# ignore time is for things like reactions
func _init(skill: Skill, direction: Vector2, hit_signal: Signal, ignore_signal := false, ignore_time_multi := false) -> void:
	_skill = skill
	_direction = direction
	_ignore_time_multi = ignore_time_multi
	if not ignore_signal:
		hit_signal.connect(_on_hit)
	else:
		_hit = true

func enter() -> void:
	super.enter()
	_character = state_machine.state_owner as Character
	_character.show_health_bar(true)


func update(delta: float) -> State:
	if _hit and not _damage_taken:
		_character.take_damage(_skill, _direction, _ignore_time_multi)
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

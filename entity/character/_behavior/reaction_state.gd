class_name ReactionState
extends State

var _character: Character
var _reaction: Reaction
var _target: Character
var _exiting := false

func enter() -> void:
	var tracking_cam: TrackingCamera = (_character.get_viewport().get_camera_2d() as TrackingCamera)
	tracking_cam.follow(_character)
	await tracking_cam.position_reached 


func _init(reaction: Skill, character: Character, target: Character) -> void:
	_reaction = reaction
	_character = character
	_target = target


func update(_delta: float) -> State:
	if not is_instance_valid(_target):
		return CharacterIdleState.new()
	
	if _exiting:
		return CharacterIdleState.new()
	return


func exit() -> void:
	_character.action_processed.emit()
	_reaction.processed = true


func can_use() -> bool:
	return false

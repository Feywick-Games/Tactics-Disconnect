class_name LevelSkillSelectState
extends LevelState

func enter() -> void:
	super.enter()
	var allies : Array[Ally]
	for node: Node in _level.get_tree().get_nodes_in_group("ally"):
		allies.append(node as Ally)
	_level.ui.open_skill_select(allies)


func update(_delta : float) -> State:
	if not _level.ui.skill_select.visible:
		return LevelTurnState.new()
	return

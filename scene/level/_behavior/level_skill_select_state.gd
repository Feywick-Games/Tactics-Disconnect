class_name LevelSkillSelectState
extends LevelState

func enter() -> void:
	super.enter()
	var allies : Array[Ally]
	for node: Node in _level.get_tree().get_nodes_in_group("ally"):
		allies.append(node as Ally)
	_level.ui.open_skill_select(allies)
	_level.ui.skill_select.units_shuffled.connect(_on_units_shuffled)
	for node: Node in _level.get_tree().get_nodes_in_group("enemy"):
		var enemy: Enemy = node as Enemy
		enemy.deal_skill()


func _on_units_shuffled(allies: Array[Ally]) -> void:
	var min_idx : int = INT64_MAX
	for ally: Ally in allies:
		if ally.get_index() < min_idx:
			min_idx = ally.get_index()
	
	for ally: Ally in allies:
		ally.get_parent().move_child(ally, min_idx)
		min_idx += 1


func update(_delta : float) -> State:
	if not _level.ui.skill_select.visible:
		return LevelTurnState.new()
	return

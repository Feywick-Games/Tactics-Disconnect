class_name LevelSkillSelectState
extends LevelState

var _allies: Array[Ally]
var _enemies: Array[Enemy]

func enter() -> void:
	super.enter()
	for node: Node in _level.get_tree().get_nodes_in_group("ally"):
		var ally := node as Ally
		_allies.append(ally)
	_level.ui.open_skill_select(_allies)
	_level.ui.skill_select.units_shuffled.connect(_on_units_shuffled)
	for node: Node in _level.get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		enemy.deal_skill()
		enemy.show_health_bar(true)
		_enemies.append(enemy)


func _on_units_shuffled(allies: Array[Ally]) -> void:
	var min_idx : int = INT64_MAX
	for ally: Ally in allies:
		if ally.get_index() < min_idx:
			min_idx = ally.get_index()
	
	for ally: Ally in allies:
		ally.get_parent().move_child(ally, min_idx)
		min_idx += 1


func update(_delta : float) -> State:
	for ally: Ally in _allies:
		ally.show_health_bar(true)
	if not _level.ui.skill_select.visible:
		return LevelTurnState.new()
	return
	

func exit() -> void:
	for ally: Ally in _allies:
		ally.show_health_bar(false)
	for enemy: Enemy in _enemies:
		enemy.show_health_bar(false)

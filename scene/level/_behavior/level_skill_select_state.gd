class_name LevelSkillSelectState
extends LevelState

var _allies: Array[Ally]
var _enemies: Array[Enemy]
var _highlighted_unit: Ally
var _skills_selected := false
var _camera_leader: Node2D
var _tracking_cam: TrackingCamera
var _camera_leader_speed: float = 120

func enter() -> void:
	super.enter()
	for node: Node in _level.get_tree().get_nodes_in_group("ally"):
		var ally := node as Ally
		_allies.append(ally)
	_level.ui.open_skill_select(_allies)
	_level.ui.skill_select.units_shuffled.connect(_on_units_shuffled)
	_level.ui.skill_select.unit_highlighted.connect(_on_unit_highlighted)
	_level.ui.skill_select.skills_selected.connect(_on_skills_selected)
	for node: Node in _level.get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		enemy.deal_skill()
		enemy.show_health_bar(true)
		_enemies.append(enemy)
	_tracking_cam = _level.get_viewport().get_camera_2d()


func _on_units_shuffled(allies: Array[Ally]) -> void:
	var min_idx : int = INT64_MAX
	for ally: Ally in allies:
		if ally.get_index() < min_idx:
			min_idx = ally.get_index()
	
	for ally: Ally in allies:
		ally.get_parent().move_child(ally, min_idx)
		min_idx += 1


func _on_unit_highlighted(unit: Ally) -> void:
	_highlighted_unit = unit


func _on_skills_selected() -> void:
	_skills_selected = true


func update(delta : float) -> State:
	for ally: Ally in _allies:
		ally.show_health_bar(true, ally == _highlighted_unit)
	if _skills_selected:
		return LevelTurnState.new()
	if Input.is_action_just_pressed("inspect"):
		if _highlighted_unit:
			_camera_leader = Node2D.new()
			_camera_leader.global_position = _highlighted_unit.global_position
			_tracking_cam.follow(_camera_leader)
	
	if Input.is_action_pressed("inspect"):
		if _camera_leader:
			_camera_leader.position += Input.get_vector("move_left", "move_right", "move_up", "move_down") * _camera_leader_speed * delta
	
	return


func exit() -> void:
	for ally: Ally in _allies:
		ally.show_health_bar(false)
	for enemy: Enemy in _enemies:
		enemy.show_health_bar(false)

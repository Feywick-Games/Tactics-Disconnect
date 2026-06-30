class_name SkillSelect
extends PanelContainer

@export
var aoe_empty_color: Color = "#433045"
@export
var aoe_origin_color: Color = "#d6d0c1"
@export
var aoe_fill_color: Color = "#a83649"

const unit_skill_list_scene: PackedScene = preload("res://ui/skill_select/_packed_scene/unit_skill_list.tscn")

var unit_skills_selected: Dictionary[Ally, Skill]

@onready
var skill_name_label: Label = %SkillName
@onready
var skill_damage_label: Label = %DamageLabel
@onready
var range_label: Label = %RangeLabel
@onready
var aoe_display: AoeDisplay = %AoeDisplay
@onready
var flavor_text_label: Label = %FlavorText
@onready
var unit_skill_lists: VBoxContainer = %UnitSkills
@onready
var go_button: TextureButton = %GoButton

func _ready() -> void:
	EventBus.encounter_started.connect(_on_skill_select_opened)
	EventBus.skill_select_opened.connect(_on_skill_select_opened)
	go_button.pressed.connect(_on_go_button_pressed)
	hide()


func _on_go_button_pressed() -> void:
	for unit: Ally in unit_skills_selected.keys():
		unit.special = unit_skills_selected[unit]
		unit.current_skill_hand.erase(unit.special)
	EventBus.skills_selected.emit()
	hide()


func _on_skill_select_opened() -> void:
	show()
	go_button.disabled = true
	for ally in GameState.allies:
		unit_skills_selected[ally] = null
	
	display_unit_skill_lists()


func display_unit_skill_lists() -> void:
	for child: UnitSkillList in %UnitSkills.get_children():
		child.free()
	
	var first_button_grabbed := false
	
	for unit: Ally in GameState.allies:
		var unit_skill_list: UnitSkillList = unit_skill_list_scene.instantiate()
		unit_skill_lists.add_child(unit_skill_list)
		unit_skill_list.deal(unit)
		for button: SkillSelectButton in unit_skill_list.skill_buttons:
			if not first_button_grabbed:
				first_button_grabbed = true
				button.grab_focus.call_deferred()
			button.skill_selected.connect(_on_skill_selected)
			button.skill_focused.connect(_on_skill_focused)
			button.skill_canceled.connect(_on_skill_canceled)
		
	_generate_button_neighbors()


func _generate_button_neighbors() -> void:
	go_button.focus_neighbor_left = go_button.get_path()
	go_button.focus_neighbor_right = go_button.get_path()
	
	var button_matrix: Array[Array] = []
	for button_list: UnitSkillList in %UnitSkills.get_children():
		button_matrix.append([])
		for button: SkillSelectButton in button_list.skill_buttons:
			if button.has_skill and (not button.disabled or button.selected):
				button_matrix[-1].append(button)
		
	for y in range(button_matrix.size()):
		for x in range(button_matrix[y].size()):
			var button: SkillSelectButton = button_matrix[y][x]
			if button.selected:
				# minus one is due to sharing a vbox container with the character sprite
				x = button.get_index() - 1
			
			var left_neighbor := Vector2i(x-1,y)
			var right_neighbor := Vector2i(x+1,y)
			var up_neighbor := Vector2i(x,y-1)
			var down_neighbor := Vector2i(x,y+1)
			if x == 0 or button.selected:
				left_neighbor.x = button_matrix[y].size() - 1
			if x >= button_matrix[y].size() - 1:
				right_neighbor.x = 0
			
			if y == 0:
				up_neighbor.y = button_matrix.size() - 1
			if y == button_matrix.size() - 1:
				down_neighbor.y = 0
			
			up_neighbor.x = min(up_neighbor.x, button_matrix[up_neighbor.y].size() - 1)
			down_neighbor.x = min(down_neighbor.x, button_matrix[down_neighbor.y].size() - 1)
			
						
			button.focus_neighbor_left = button_matrix[left_neighbor.y][left_neighbor.x].get_path()
			button.focus_neighbor_right = button_matrix[right_neighbor.y][right_neighbor.x].get_path()

			
			if y == 0:
				if go_button.disabled:
					button.focus_neighbor_top = button_matrix[up_neighbor.y][up_neighbor.x].get_path()
				else:
					button.focus_neighbor_top = go_button.get_path()
					if x == 0 or button.selected:
						go_button.focus_neighbor_bottom = button.get_path()
			else:
				button.focus_neighbor_top = button_matrix[up_neighbor.y][up_neighbor.x].get_path()

			
			if y == button_matrix.size() - 1:
				if go_button.disabled:
					button.focus_neighbor_bottom = button_matrix[down_neighbor.y][down_neighbor.x].get_path()
				else:
					button.focus_neighbor_bottom = go_button.get_path()
					if x == 0 or button.selected:
						go_button.focus_neighbor_top = button.get_path()
			else:
				button.focus_neighbor_bottom = button_matrix[down_neighbor.y][down_neighbor.x].get_path()

			


func _on_skill_focused(skill: Skill) -> void:
	skill_name_label.text = skill.name
	skill_damage_label.text = str(skill.get_hit_damage())
	range_label.text = str(skill.max_range)
	flavor_text_label.text = skill.flavor_text
	_fill_aoe_display(skill.aoe)
	


func _on_skill_canceled(ally: Ally, _skill: Skill) -> void:
	unit_skills_selected[ally] = null
	go_button.disabled = true
	_generate_button_neighbors()


func _fill_aoe_display(aoe: Array[Vector2i]) -> void:
	var i: int = 0
	var max_y: int = 0
	var translated_tiles: Array[Vector2i]
	
	for vec: Vector2i in aoe:
		if vec.y > max_y:
			max_y = vec.y
			
	var init_tile: Vector2i = Vector2i(2,2) if max_y < 2 else Vector2i(2, max_y)
	
	for vec: Vector2i in aoe:
		var tile : Vector2i = vec + init_tile
		translated_tiles.append(tile)
	
	for child: ColorRect in %AoeDisplay.get_node("MarginContainer/GridContainer").get_children():
		var vec := Vector2i.ZERO
		vec.x = i % 5
		vec.y = int(float(i) / 5.0)
		
		if vec in translated_tiles and not vec == init_tile:
			child.color = aoe_fill_color
		elif vec == init_tile:
			child.color = aoe_origin_color
		else:
			child.color = aoe_empty_color
		
		i += 1



func _on_skill_selected(ally: Ally, skill: Skill) -> void:
	unit_skills_selected[ally] = skill	
	var has_null_skills := false
	for skill_value: Skill in unit_skills_selected.values():
		if skill_value == null:
			has_null_skills = true
			
	if not has_null_skills:
		go_button.disabled = false
	
	_generate_button_neighbors()

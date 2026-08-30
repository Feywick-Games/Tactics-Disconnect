class_name UnitSkillList
extends VBoxContainer

signal child_focus_entered
signal shuffle_confirmed
signal reordered(unit_skill_list: UnitSkillList, up: bool)
signal shuffle_canceled(unit_skill_list: UnitSkillList, idx: int)


@onready
var _character_name_label: Label = %CharacterNameLabel
@onready
var unit_button: UnitSelectButton = %UnitButton
@onready
var skill_buttons: Array[SkillSelectButton] = [%SkillButton1, %SkillButton2, %SkillButton3]
@onready
var reorder_pointer: TextureRect = %ReorderPointer
@onready
var reorder_animator: AnimationPlayer = %ReorderAnimator
var selecting := false
var current_idx: int
var ally: Ally

func _ready() -> void:
	for button: SkillSelectButton in skill_buttons:
		button.skill_selected.connect(_on_skill_selected)
		button.skill_canceled.connect(_on_skill_canceled)
		button.focus_entered.connect(_on_child_focus_entered)
	unit_button.focus_entered.connect(_on_child_focus_entered)
	unit_button.unit_selected.connect(_on_unit_selected)
	reorder_pointer.hide()


func _input(event: InputEvent) -> void:
	if selecting and visible:
		if event.is_action_pressed("move_down", true):
			reorder_animator.play("down")
			reorder_animator.advance(0)
			reorder_animator.queue("flicker")
			reordered.emit(self, false)
		elif event.is_action_pressed("move_up", true):
			reorder_animator.play("up")
			reorder_animator.advance(0)
			reorder_animator.queue("flicker")
			reordered.emit(self, true)
		elif event.is_action_pressed("cancel"):
			_on_shuffle_canceled()
		elif event.is_action_pressed("accept"):
			_confirm_position()
		accept_event()


func _on_unit_selected() -> void:
	if not selecting:
		unit_button.focus_neighbor_left = "."
		unit_button.focus_neighbor_right = "."
		unit_button.focus_neighbor_top = "."
		unit_button.focus_neighbor_bottom = "."
		reorder_pointer.show()
		reorder_animator.play("flicker")
		reorder_animator.advance(0)
		current_idx = get_index()
		selecting = true
		get_viewport().set_input_as_handled()


func _on_shuffle_canceled() -> void:
	if selecting:
		reorder_pointer.hide()
		selecting = false
		shuffle_canceled.emit(self, current_idx)


func _confirm_position() -> void:
	reorder_pointer.hide()
	selecting = false
	current_idx = get_index()
	shuffle_confirmed.emit()


func _on_child_focus_entered() -> void:
	child_focus_entered.emit()


func deal(unit: Ally) -> void:
	_character_name_label.text = unit.character_name
	unit.deal_skills()
	
	var skill_hand : Array[Skill] = unit.current_skill_hand
	
	for button : SkillSelectButton in skill_buttons:
		button.unload()
	
	var i: int = 0
	for skill: Skill in skill_hand:
		skill_buttons[i].setup(unit, skill)
		i += 1
	
	unit_button.setup(unit)
	ally = unit
	

func _on_skill_selected(_ally: Ally, _skill: Skill) -> void:
	for button: SkillSelectButton in skill_buttons:
		button.disabled = true
		

func _on_skill_canceled(_ally: Ally, _skill: Skill) -> void:
	for button: SkillSelectButton in skill_buttons:
		button.reset()
		

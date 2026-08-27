class_name UnitSelectButton
extends TextureButton

signal unit_selected
signal shuffle_canceled
signal unit_focused(unit: Ally)

var _ally: Ally
var focus_material: ShaderMaterial = load("res://ui/skill_select/_material/unit_select_focus_material.tres")


func _ready() -> void:
	pressed.connect(_on_button_pressed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _on_focus_entered() -> void:
	material = focus_material
	unit_focused.emit(_ally)


func _on_focus_exited() -> void:
	material = null


func _on_button_pressed() -> void:
	unit_selected.emit()


func setup(ally: Ally) -> void:
	_ally = ally
	texture_normal = ally.small_portrait

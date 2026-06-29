class_name SkillSelectButton
extends TextureButton


signal skill_selected(ally: Ally, skill: Skill)
signal skill_focused(skill: Skill)
signal skill_canceled(ally: Ally, skill: Skill)

const UI_EMPTY_ATLAS: Texture2D = preload("res://ui/skill_select/_sprite/skill_sprite_empty.png")
var _empty_tex := AtlasTexture.new()
var _empty_tex_disable := AtlasTexture.new()
var _ally: Ally
var _skill: Skill
var _skill_tex := AtlasTexture.new()
var _skill_tex_disable := AtlasTexture.new()
var selected := false

@onready
var focus_material: ShaderMaterial = load("res://ui/skill_select/_material/button_focus_material.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disabled = true
	_empty_tex.atlas = UI_EMPTY_ATLAS
	_empty_tex.region = Rect2(Vector2.ZERO, Skill.UI_SMALL_DIMENSIONS)
	_empty_tex.atlas = UI_EMPTY_ATLAS
	_empty_tex.region = Rect2(Vector2(Skill.UI_SMALL_DIMENSIONS.x, 0), Skill.UI_SMALL_DIMENSIONS)
	texture_disabled = _empty_tex
	pressed.connect(_on_button_pressed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("cancel") and has_focus():
		skill_canceled.emit(_ally, _skill)


func _on_focus_entered() -> void:
	material = focus_material
	skill_focused.emit(_skill)


func _on_focus_exited() -> void:
	material = null


func _on_button_pressed() -> void:
	texture_disabled = _skill_tex
	selected = true
	skill_selected.emit(_ally, _skill)


func reset() -> void:
	disabled = false
	texture_disabled = _skill_tex_disable if _skill_tex_disable else _empty_tex
	selected = false


func unload() -> void:
	disabled = true
	texture_disabled = _empty_tex
	_skill = null
	_ally = null
	_skill_tex = null
	_skill_tex_disable = null


func setup(ally: Ally, skill: Skill) -> void:
	disabled = false
	_skill_tex = AtlasTexture.new()
	_skill_tex.atlas = skill.ui_small
	_skill_tex.region = Rect2(Vector2.ZERO, Skill.UI_SMALL_DIMENSIONS)
	_skill_tex_disable = AtlasTexture.new()
	_skill_tex_disable.atlas = skill.ui_small
	_skill_tex_disable.region = Rect2(Vector2(Skill.UI_SMALL_DIMENSIONS.x, 0), Skill.UI_SMALL_DIMENSIONS)
	texture_normal = _skill_tex
	texture_disabled = _skill_tex_disable
	_skill = skill
	_ally = ally

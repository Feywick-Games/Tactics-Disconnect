class_name Enemy
extends Character

const DISTANCE_PRIORITY: float = .5

@export_category("AI Prioritization")
@export_range(0,1)
var damage_priority: float = 0.5
@export_range(0,1)
var basic_skill_priority: float = 0.5
@export_range(0,1)
var knock_out_priority: float = 0.75
@export_range(0,1)
var safety_priority: float = 0.5
@export_range(0,1)
var special_priority: float = 0.75
@export_range(0,1)
var custom_priority: float = 0


func _ready() -> void:
	super._ready()

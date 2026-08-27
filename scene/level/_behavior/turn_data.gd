class_name TurnData
extends Node

class Serialization:
	var turn_number: int
	var active_character_node_name: String
	var is_ally: bool
	var attacked : bool
	var used_skill_name: String
	var special_used: bool
	var target_character_node_names: Array[String]
	var start_position: Vector2i
	var end_position: Vector2i
	
	func _init(turn_data: TurnData) -> void:
		var target_names : Array[String] = []
		var skill_name : String
		if turn_data.active_skill_state and turn_data.active_skill_state.targets:
			for target: Character in turn_data.active_skill_state.targets:
				target_names.append(target.name)
		if turn_data.active_skill_state:
			skill_name = turn_data.active_skill_state.skill.name
		turn_number = turn_data.turn_number
		active_character_node_name = turn_data.active_unit.name
		is_ally = turn_data.active_unit is Ally
		attacked = turn_data.attacked
		used_skill_name = skill_name
		special_used = turn_data.special_used
		target_character_node_names = target_names
		start_position = turn_data.start_position
		end_position = turn_data.active_unit.current_tile
		
		

var force_show_health := false
var active_unit: Character
var special_used: bool
var attacked: bool
var start_position: Vector2i
var turn_number: int
var skill_started := false

var active_skill_state: SkillState:
	set(val):
		if val != null:
			if not val is BasicSkillState:
				special_used = true
			else:
				special_used = false
			attacked = true
		else:
			attacked = false
			special_used = false
		active_skill_state = val


func _init(turn_idx: int, unit: Character) -> void:
	turn_number = turn_idx
	active_unit = unit
	start_position = active_unit.current_tile


func get_final_data() -> TurnData.Serialization:
	return TurnData.Serialization.new(self)
	

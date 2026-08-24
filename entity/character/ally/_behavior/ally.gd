class_name Ally
extends Character

@export
var small_portrait: Texture2D
@export
var large_portrait: Texture2D
@export_multiline
var skill_select_description: String

var skills_dealt: int = 3

var current_skill_deck: Array[Skill]
var current_skill_hand: Array[Skill]

func _ready() -> void:
	super._ready()
	current_skill_deck = skill_deck
	current_skill_deck.shuffle()


func deal_skills() -> void:
	if skills_dealt - current_skill_hand.size() > current_skill_deck.size():
		var new_deck : Array[Skill] = skill_deck
		for skill: Skill in current_skill_deck:
			new_deck.erase(skill)
		new_deck.shuffle()
		current_skill_deck.append_array(new_deck)
	
	for i in range(current_skill_hand.size(), skills_dealt):
		current_skill_hand.append(current_skill_deck.pop_front())

class_name TurnDisplay
extends BoxContainer

func start_turn(units: Array[Character]) -> void:
	for child in get_children():
		remove_child(child)
	
	for unit: Character in units:
		var turn_portait: TurnPortrait = unit.turn_portrait_scene.instantiate()
		turn_portait.set_up(unit)
		add_child(turn_portait)
		
	get_child(0).display_full_portrait()

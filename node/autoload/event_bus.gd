extends Node

@warning_ignore("unused_signal")
signal encounter_started
@warning_ignore("unused_signal")
signal encounter_ended
@warning_ignore("unused_signal")
signal room_transitioned(room: Room, loaded: bool)
@warning_ignore("unused_signal")
signal build_battle_map(rooms: Array[Room])
@warning_ignore("unused_signal")
signal tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], accuracy: int)
@warning_ignore("unused_signal")
signal display_requested(show_display: bool)

@warning_ignore("unused_signal")
signal turn_started(unit: Character)
@warning_ignore("unused_signal")
signal turn_ended(unit_name: String)
@warning_ignore("unused_signal")
signal reaction_requested(unit: Character)
@warning_ignore("unused_signal")
signal timed_out
@warning_ignore("unused_signal")
signal timer_stopped
@warning_ignore("unused_signal")
signal skill_progress_ready
@warning_ignore("unused_signal")
signal skills_selected
@warning_ignore("unused_signal")
signal skill_select_opened

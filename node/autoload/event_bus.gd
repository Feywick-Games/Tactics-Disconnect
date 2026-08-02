extends Node

# Level
@warning_ignore("unused_signal")
signal encounter_started
@warning_ignore("unused_signal")
signal encounter_ended

# UI
@warning_ignore("unused_signal")
signal tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], accuracy: int)
@warning_ignore("unused_signal")
signal display_requested(show_display: bool)
@warning_ignore("unused_signal")
signal skill_display_requested(skill_name: String)

# turn order
@warning_ignore("unused_signal")
signal turn_started(unit: Character)
@warning_ignore("unused_signal")
signal spawns_processed()
@warning_ignore("unused_signal")
signal turn_ended(unit_name: String)
@warning_ignore("unused_signal")
signal reaction_requested(unit: Character)
@warning_ignore("unused_signal")
signal timed_out
@warning_ignore("unused_signal")
signal timer_stopped

# skills
@warning_ignore("unused_signal")
signal skill_progress_ready
@warning_ignore("unused_signal")
signal skills_selected
@warning_ignore("unused_signal")
signal skill_select_opened
@warning_ignore("unused_signal")
signal skill_error_encountered(code: Global.SkillErrorCode)

# camera
@warning_ignore("unused_signal")
signal cam_follow_requested(unit: Character, offset: Vector2)
@warning_ignore("unused_signal")
signal cam_position_reached

# skill minigames
@warning_ignore("unused_signal")
signal push_progress_requested
@warning_ignore("unused_signal")
signal push_progress_completed(value: float)

#game state
@warning_ignore("unused_signal")
signal unit_spawned(unit: Character)

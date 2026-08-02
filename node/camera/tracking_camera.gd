class_name TrackingCamera
extends Camera2D


@export
var leader : Node2D
@export_range(0,5)
var lerp_speed: float = 4
@onready
var window_scale : Vector2i
var _in_encounter := false
var in_position := false
var actual_cam_pos: Vector2


func _ready() -> void:
	EventBus.cam_follow_requested.connect(_on_cam_follow_requested)
	get_tree().root.get_viewport().size_changed.connect(_set_window_scale)
	window_scale = DisplayServer.screen_get_size()
	EventBus.encounter_started.connect(_on_encounter_started)
	actual_cam_pos = global_position
	process_priority = 1


func _on_encounter_started() -> void:
	_in_encounter = true


func _set_window_scale() -> void:
	window_scale = (Vector2(DisplayServer.window_get_size()) / Vector2(Global.GAME_SIZE)).round()


func _physics_process(delta: float) -> void:
	if leader and is_instance_valid(leader):
		if _in_encounter:
			if leader.global_position.distance_to(global_position) < 10:
				EventBus.cam_position_reached.emit()
				#actual_cam_pos = leader.global_position
			#elif leader.global_position.distance_to(global_position) < 10:
				#global_position += leader.global_position - global_position
			else:
				var cam_pos: Vector2 = global_position.lerp(leader.global_position, .2)
				actual_cam_pos =  actual_cam_pos.lerp(cam_pos, 10 * delta)
		else:
			if leader.global_position.distance_to(global_position) > 20:
				actual_cam_pos =  actual_cam_pos.lerp(leader.global_position, lerp_speed * delta)
	#global_position.y = max(global_position.y, Global.GAME_SIZE.y / 2.0)
	#global_position.x = max(global_position.x, Global.GAME_SIZE.x / 2.0)
	var cam_subpixel_offset: = (actual_cam_pos.round() - actual_cam_pos)
	GameState.level_viewport.material.set_shader_parameter("cam_offset", cam_subpixel_offset)
	global_position = actual_cam_pos.round()

func _on_cam_follow_requested(node: Node2D, requested_offset: Vector2) -> void:
	leader = node
	offset = -requested_offset/2.0

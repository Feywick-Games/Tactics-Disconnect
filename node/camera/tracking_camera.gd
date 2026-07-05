class_name TrackingCamera
extends Camera2D


@export
var leader : Node2D
@export_range(0,5)
var lerp_speed: float = 5
@export
var max_speed: float = .5
@onready
var window_scale : Vector2i
var _in_encounter := false
var in_position := false


func _ready() -> void:
	EventBus.cam_follow_requested.connect(_on_cam_follow_requested)
	get_tree().root.get_viewport().size_changed.connect(_set_window_scale)
	window_scale = DisplayServer.screen_get_size()
	EventBus.encounter_started.connect(_on_encounter_started)


func _on_encounter_started() -> void:
	_in_encounter = true


func _set_window_scale() -> void:
	window_scale = (Vector2(DisplayServer.window_get_size()) / Vector2(Global.GAME_SIZE)).round()


func _physics_process(delta: float) -> void:
	if leader and is_instance_valid(leader):
		if _in_encounter:
			if leader.global_position.distance_to(global_position) < 10 or (abs(global_position.x - leader.global_position.x) <= 2 and global_position.y < 5):
				in_position = true
				global_position = leader.global_position
			else:
				global_position =  global_position.lerp(leader.global_position, lerp_speed * delta)
				global_position = global_position.round()
				in_position = false
		else:
			if leader.global_position.distance_to(global_position) > 20:
				global_position =  global_position.lerp(leader.global_position, lerp_speed * delta)
				global_position = global_position.round()
	#global_position.y = max(global_position.y, Global.GAME_SIZE.y / 2.0)
	#global_position.x = max(global_position.x, Global.GAME_SIZE.x / 2.0)


func _on_cam_follow_requested(node: Node2D, requested_offset: Vector2) -> void:
	leader = node
	offset = -requested_offset/2.0

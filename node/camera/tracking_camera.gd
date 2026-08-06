class_name TrackingCamera
extends Camera2D

@export
var leader : Node2D
@export_range(0,5)
var lerp_speed: float = 4
@onready
var window_scale : Vector2i
var actual_cam_pos: Vector2
var in_position: bool = true

func _ready() -> void:
	get_tree().root.get_viewport().size_changed.connect(_set_window_scale)
	window_scale = DisplayServer.screen_get_size()
	actual_cam_pos = global_position
	process_priority = 1


func _set_window_scale() -> void:
	window_scale = (Vector2(DisplayServer.window_get_size()) / Vector2(Global.GAME_SIZE)).round()


func _physics_process(delta: float) -> void:
	if leader and is_instance_valid(leader):
		if leader.global_position.distance_to(global_position) < 10:
			in_position = true
		else:
			var cam_pos: Vector2 = global_position.lerp(leader.global_position, .2)
			actual_cam_pos =  actual_cam_pos.lerp(cam_pos, 10 * delta)

	var cam_subpixel_offset: = (actual_cam_pos.round() - actual_cam_pos)
	GameState.game.viewport_container.material.set_shader_parameter("cam_offset", cam_subpixel_offset)
	global_position = actual_cam_pos.round()


func follow(node: Node2D, follow_offset: Vector2 = Vector2.ZERO) -> void:
	leader = node
	offset = -follow_offset/2.0
	in_position = false

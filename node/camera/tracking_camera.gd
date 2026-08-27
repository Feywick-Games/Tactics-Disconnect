class_name TrackingCamera
extends Camera2D

@export
var leader : Node2D
@onready
var window_scale : Vector2i
var actual_cam_pos: Vector2
var in_position: bool = true
var speed: float = 0
var max_speed: float = .2


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
			speed = 0
		else:
			speed = lerp(speed,max_speed, 5 * delta)
			var cam_pos: Vector2 = global_position.lerp(leader.global_position, speed)
			actual_cam_pos =  actual_cam_pos.lerp(cam_pos, 10 * delta)

	var cam_subpixel_offset: = (actual_cam_pos.round() - actual_cam_pos)
	GameState.game.viewport_container.material.set_shader_parameter("cam_offset", cam_subpixel_offset)
	global_position = actual_cam_pos.round()


func follow(node: Node2D) -> void:
	leader = node
	in_position = false

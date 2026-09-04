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
var bounds: Rect2


func _ready() -> void:
	get_tree().root.get_viewport().size_changed.connect(_set_window_scale)
	window_scale = DisplayServer.screen_get_size()
	actual_cam_pos = global_position
	process_priority = 1


func _set_window_scale() -> void:
	window_scale = (Vector2(DisplayServer.window_get_size()) / Vector2(Global.GAME_SIZE)).round()


func _physics_process(delta: float) -> void:
	if leader and is_instance_valid(leader):
		# messes up when the lines overlap but don't "intersect" so there is a small shrinking offset passed in to make sure they interserct.
		var point : Vector2 = leader.global_position
		
		if not bounds.has_point(leader.global_position):
			#point = VectorF.get_rect_line_intersection(bounds.grow(-.001), bounds.get_center(), leader.global_position)
			if leader.global_position.x <= bounds.end.x and leader.global_position.x >= bounds.position.x:
				point.x = leader.global_position.x
			elif leader.global_position.x > bounds.end.x:
				point.x = bounds.end.x
			else:
				point.x = bounds.position.x
			if leader.global_position.y <= bounds.end.y and leader.global_position.y >= bounds.position.y:
				point.y = leader.global_position.y
			elif leader.global_position.y > bounds.end.y:
				point.y = bounds.end.y
			else:
				point.y = bounds.position.y
		
		
		if point.distance_to(global_position) < 10:
			in_position = true
			speed = 0
		else:
			speed = lerp(speed,max_speed, 5 * delta)
			var cam_pos: Vector2 = global_position.lerp(point, speed)
			actual_cam_pos =  actual_cam_pos.lerp(cam_pos, 10 * delta).clamp(bounds.position, bounds.end)

	var cam_subpixel_offset: = (actual_cam_pos.round() - actual_cam_pos)
	GameState.game.viewport_container.material.set_shader_parameter("cam_offset", cam_subpixel_offset)
	global_position = actual_cam_pos.round()


func follow(node: Node2D) -> void:
	leader = node
	in_position = false

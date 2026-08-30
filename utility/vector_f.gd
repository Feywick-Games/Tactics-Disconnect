class_name VectorF
extends Node

static func snap_direction(direction: Vector2) -> Vector2:
	var theta : float = direction.angle()
	
	if direction != Vector2.ZERO:
		# use is equal approx to force a proper less than on floating points
		if (theta < (-PI * 3.0/4.0) and not is_equal_approx(theta, -PI *  3.0/4.0)):
			direction = Vector2.LEFT
		elif (theta < -PI * 1.0/4.0 and not is_equal_approx(theta, -PI *  1.0/4.0)):
			direction = Vector2.UP
		elif (theta < PI * 1.0/4.0 and not is_equal_approx(theta, PI *  1.0/4.0)):
			direction = Vector2.RIGHT
		elif (theta < PI * 3.0/4.0 and not is_equal_approx(theta, PI *  3.0/4.0)):
			direction = Vector2.DOWN
		else:
			direction = Vector2.LEFT
	return direction


static func get_rect_line_intersection(rect: Rect2, line_start: Vector2, line_end: Vector2) -> Vector2:
	# Define the 4 corners of the rectangle
	var top_left: Vector2 = rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	var bottom_right: Vector2 = rect.end
	
	# Define the 4 border lines of the rectangle
	var sides : Array[Array] = [
		[top_left, top_right],      # Top side
		[top_right, bottom_right],  # Right side
		[bottom_right, bottom_left],# Bottom side
		[bottom_left, top_left]     # Left side
	]
	
	# Check the line segment against each side of the rectangle
	for side in sides:
		var intersection: Variant = Geometry2D.segment_intersects_segment(line_start, line_end, side[0], side[1])
		if intersection != null:
			return intersection # Returns the Vector2 point of collision
			
	return line_start

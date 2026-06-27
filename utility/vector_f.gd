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

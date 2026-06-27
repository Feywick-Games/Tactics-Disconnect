class_name DirectionalAnimator
extends AnimationPlayer

var current_direction : String = "down"


# if playing an eight directional animation we do not want to cache it as not all animations 
# have this degree of cardinality.

# alt_ext can be used when dependent other animations
func play_directional(anim: String, direction:= Vector2.ZERO, queue_anim := false, alt_ext := "",
custom_blend: float = -1,custom_speed: float = 1.0, from_end: bool = false) -> void:
	var anim_direction_str : String = get_current_direction(direction)
	anim_direction_str += alt_ext
	
	current_direction = anim_direction_str
	
	if not queue_anim:
		play(anim + "_" + anim_direction_str, custom_blend, custom_speed, from_end)
	else:
		queue(anim + "_" + anim_direction_str)


func get_current_direction(direction: Vector2) -> String:
	var theta : float = direction.angle()
	var eight_direction_str := ""
	if direction != Vector2.ZERO:
		# use is equal approx to force a proper less than on floating points
		if (theta < (-PI * 3.0/4.0) and not is_equal_approx(theta, -PI *  3.0/4.0)) or \
		(current_direction == "left" and is_equal_approx(theta, -PI *  3.0/4.0)):
			current_direction = "left"
		elif (theta < -PI * 1.0/4.0 and not is_equal_approx(theta, -PI *  1.0/4.0)) \
		or (current_direction == "up" and is_equal_approx(theta, -PI *  1.0/4.0)):
			current_direction = "up"
		elif (theta < PI * 1.0/4.0 and not is_equal_approx(theta, PI *  1.0/4.0)) \
		or (current_direction == "right" and is_equal_approx(theta, PI *  1.0/4.0)):
			current_direction = "right"
		elif (theta < PI * 3.0/4.0 and not is_equal_approx(theta, PI *  3.0/4.0)) \
		or (current_direction == "down" and is_equal_approx(theta, PI * 3.0/4.0)):
			current_direction = "down"
		else:
			current_direction = "left"
	
	var anim_direction_str := eight_direction_str if not eight_direction_str.is_empty() else current_direction

	return anim_direction_str

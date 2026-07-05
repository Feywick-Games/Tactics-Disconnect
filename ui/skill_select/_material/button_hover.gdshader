shader_type canvas_item;

uniform vec2 texture_scale = vec2(2.0, 1.0);
uniform vec4 flash_color : source_color;
uniform vec4 highlight_color: source_color;

void fragment() {
	bool is_outside = false;
	vec2 uv_scaled = UV * texture_scale;
	vec2 pixel_size_scaled = TEXTURE_PIXEL_SIZE * texture_scale;

	
	if (uv_scaled.x < pixel_size_scaled.x * 2.0)
	{
		is_outside = true;
	}
	else if (uv_scaled.x > 1.0 - (pixel_size_scaled.x * 2.0))
	{
		is_outside = true;
	}
	else if (uv_scaled.y < (pixel_size_scaled.y * 2.0))
	{
		is_outside = true;
	}
	else if (uv_scaled.y > 1.0 - (pixel_size_scaled.y * 2.0))
	{
		is_outside = true;
	}
	
	float time_rotate = atan(cos(TIME * 3.0), sin(TIME * 3.0)) / PI;
	float time_rotate_offset = atan(cos(TIME * 3.0), sin(TIME * 3.0)) / PI + (PI/4.0);
	
	if (time_rotate < 0.0)
	{
		time_rotate += 1.0;
	}
	if (time_rotate_offset < 0.0)
	{
		time_rotate_offset += 1.0;
	}
	if (time_rotate_offset > 1.0)
	{
		time_rotate_offset -= 1.0;
	}
	
	float uv_angle = atan(uv_scaled.x - .5, uv_scaled.y - .5) / PI;
	float uv_angle_offset = atan(uv_scaled.x - .5, uv_scaled.y - .5) / PI + (PI/4.0);
	
	if (uv_angle < 0.0)
	{
		uv_angle += 1.0;
	}
	
	if (uv_angle_offset < 0.0)
	{
		uv_angle_offset += 1.0;
	}
	if (uv_angle_offset > 1.0)
	{
		uv_angle_offset -= 1.0;
	}

	if (is_outside == true && (abs(time_rotate - uv_angle) < pixel_size_scaled.x * 2.0 || abs(time_rotate_offset - uv_angle_offset) < pixel_size_scaled.x * 2.0) )
	{
		COLOR = highlight_color;
	}
	else if (!is_outside)
	{
		COLOR = texture(TEXTURE, UV);
	}
	else
	{
		COLOR = flash_color;
	}

	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

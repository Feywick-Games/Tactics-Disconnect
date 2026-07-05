shader_type canvas_item;
render_mode blend_add; // This makes it ‘glow’ against the world

uniform vec4 color : source_color;
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform vec4 glow_color_2 : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float pulse_speed : hint_range(0.0, 100.0) = 20;

void fragment() {
 	vec4 col = color;
  	float offset = (float(int(TIME * pulse_speed) % 100) *.01) - .1;
	float new_uv_x = UV.x * .6;

	
	if (abs(offset - new_uv_x) < .1)
	{
		col = glow_color;
	}
	else if (abs(offset - new_uv_x) < .15)
	{
		col = glow_color_2;
	}
  // 4. THE FIX: Multiply by sprite_shape so the glow stays 
  // within the bounds of the sprite (prevents a giant square box)
  COLOR = col;
}

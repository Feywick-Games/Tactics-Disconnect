shader_type canvas_item;

uniform vec4 color : source_color;
uniform vec4 glow_color : source_color;
uniform vec4 glow_color_2 : source_color;
uniform float pulse_speed : hint_range(0.0, 100.0) = 20;
uniform sampler2D glow_area;
uniform int value;

void fragment() {
	vec4 tex_col = texture(TEXTURE, UV);
	vec4 glow_tex_col = texture(glow_area, UV);
	float progress = float(value)/3.0;
	
	if (UV.x <= progress)
	{
		if (glow_tex_col.a == 1.0)			//COLOR = glow_color;

		{
			vec4 col = color;
			float offset = (float(int(TIME * pulse_speed) % 100) *.01) - .1;
			float new_uv_x = UV.y * .6;
			
			if (abs(offset - new_uv_x) < .1)
			{
				col = glow_color;
			}
			else if (abs(offset - new_uv_x) < .15)
			{
				col = glow_color_2;
			}

			col.a *= tex_col.a;
			tex_col = col;
		}
		
	}
  COLOR = tex_col;
}

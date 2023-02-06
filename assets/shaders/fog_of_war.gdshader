// Adapted from 2d waterfall shader 
// https://godotshaders.com/shader/2d-waterfall/

shader_type canvas_item;

uniform sampler2D wind_noise: repeat_enable;
uniform vec4 cloud_tint : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 cloud_highlight : source_color = vec4(0.5, 0.5, 0.5, 0.6);
uniform vec2 wind_stretch = vec2(5.0, 1.0);
uniform float wind_speed : hint_range(0.0, 5.0, 0.05) = 0.5;
uniform float wind_gaps : hint_range(0.0, 1.0, 0.01) = 0.33;
uniform float edge_width : hint_range(0.0, 0.3) = 0.02;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


void fragment() {
	// Grab screen texture
	vec4 current_tex = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 color = current_tex;
	
	// If not visible, make noisy
	if (current_tex == vec4(0.0, 0.0, 0.0, 1.0) || current_tex == vec4(77.0/255.0, 77.0/255.0, 77.0/255.0, 1.0)){
		
		vec2 cloud_mask = texture(wind_noise, vec2(UV.x + TIME * wind_speed, UV.y + 0.2*sin(TIME/(2.0*PI))) * wind_stretch).xy;
		
		float edges = wind_gaps + edge_width;
		
		if (cloud_mask.x < edges){
			color.rgb = mix(color.rgb, cloud_highlight.rgb, cloud_highlight.a);
		} else {
			color.rgb = mix(color.rgb, cloud_tint.rgb, cloud_tint.a);
		}
		
		if (cloud_mask.y < wind_gaps) {
			color.rgb = mix(color.rgb, vec3(0.4), 0.5);
		}
		
		
		
	}
	
	COLOR = color;
}

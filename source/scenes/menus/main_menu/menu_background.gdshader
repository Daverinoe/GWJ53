shader_type canvas_item;

uniform sampler2D track_texture: repeat_enable;
uniform float scroll_speed = 0.0;

void fragment() {
	COLOR = texture(track_texture, UV + vec2(TIME * scroll_speed, 0.0));
}

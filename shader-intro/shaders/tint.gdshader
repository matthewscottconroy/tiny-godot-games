shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	COLOR = vec4(mix(col.rgb, tint_color.rgb, mix_amount * col.a), col.a);
}

shader_type canvas_item;

uniform vec4 body_src   : source_color = vec4(0.12, 0.56, 1.00, 1.0);
uniform vec4 armor_src  : source_color = vec4(1.00, 0.84, 0.00, 1.0);
uniform vec4 body_dst   : source_color = vec4(0.12, 0.56, 1.00, 1.0);
uniform vec4 armor_dst  : source_color = vec4(1.00, 0.84, 0.00, 1.0);
uniform float threshold : hint_range(0.0, 0.5) = 0.18;

// Godot's shading language does not allow `return` inside fragment(), so the
// transparent-pixel case is an ordinary branch rather than an early exit.
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.01) {
		COLOR = col;
	} else if (distance(col.rgb, body_src.rgb) < threshold) {
		COLOR = vec4(body_dst.rgb, col.a);
	} else if (distance(col.rgb, armor_src.rgb) < threshold) {
		COLOR = vec4(armor_dst.rgb, col.a);
	} else {
		COLOR = col;
	}
}

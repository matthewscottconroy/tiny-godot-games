shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 0.1) = 0.025;
uniform float frequency : hint_range(1.0, 20.0) = 8.0;
uniform float speed     : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	float offset_x = sin(UV.y * frequency + TIME * speed) * amplitude;
	float offset_y = cos(UV.x * frequency + TIME * speed) * amplitude;
	vec2 distorted  = UV + vec2(offset_x, offset_y);
	// Clamp to avoid edge sampling artifacts
	distorted = clamp(distorted, vec2(0.001), vec2(0.999));
	COLOR = texture(TEXTURE, distorted);
}

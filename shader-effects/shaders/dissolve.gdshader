shader_type canvas_item;

// dissolve_amount: 0 = fully visible, 1 = fully dissolved
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
// Edge color shown as the surface burns away
uniform vec4 edge_color : source_color = vec4(1.0, 0.4, 0.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i),               hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float n = noise(UV * 7.0);
	if (n < dissolve_amount) {
		discard;
	}
	float edge = step(n, dissolve_amount + 0.06) * col.a;
	COLOR = mix(col, vec4(edge_color.rgb, col.a), edge);
}

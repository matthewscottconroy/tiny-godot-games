shader_type canvas_item;

uniform vec2 light_uv = vec2(0.5, 0.5);
uniform vec4 light_color : source_color = vec4(1.0, 0.92, 0.7, 1.0);
uniform float light_radius : hint_range(0.1, 2.0) = 0.6;
uniform float bump_strength : hint_range(0.0, 4.0) = 2.0;
uniform float freq : hint_range(1.0, 30.0) = 10.0;

float height_field(vec2 uv) {
	return sin(uv.x * freq) * cos(uv.y * freq * 0.8) * 0.5
		 + sin(uv.x * freq * 0.6 + 1.0) * sin(uv.y * freq * 1.3) * 0.3
		 + cos(uv.x * freq * 1.7 - 0.5) * cos(uv.y * freq * 0.9 + 0.8) * 0.2;
}

vec3 bump_normal(vec2 uv) {
	float eps = 0.002;
	float dx = height_field(uv + vec2(eps, 0.0)) - height_field(uv - vec2(eps, 0.0));
	float dy = height_field(uv + vec2(0.0, eps)) - height_field(uv - vec2(0.0, eps));
	return normalize(vec3(-dx * bump_strength, -dy * bump_strength, 1.0));
}

void fragment() {
	vec3 N = bump_normal(UV);
	vec2 light_dir2d = light_uv - UV;
	float dist = length(light_dir2d);
	float atten = 1.0 / (1.0 + dist * dist * 30.0 / (light_radius * light_radius));
	vec3 L = normalize(vec3(light_dir2d / max(dist, 0.001), 0.35));
	float diff = max(dot(N, L), 0.0);
	vec3 base = vec3(0.22, 0.18, 0.32);
	vec3 lit = base + light_color.rgb * diff * atten * 1.8;
	COLOR = vec4(lit, 1.0);
}

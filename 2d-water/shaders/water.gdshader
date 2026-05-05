shader_type canvas_item;

uniform float wave_speed     : hint_range(0.1, 5.0) = 1.2;
uniform float wave_amplitude : hint_range(0.0, 0.05) = 0.018;
uniform float wave_frequency : hint_range(1.0, 20.0) = 6.0;
uniform float foam_threshold : hint_range(0.0, 1.0)  = 0.85;
uniform vec4  water_color    : source_color = vec4(0.05, 0.35, 0.75, 0.88);
uniform vec4  foam_color     : source_color = vec4(0.8,  0.9,  1.0,  0.95);
uniform vec4  deep_color     : source_color = vec4(0.02, 0.15, 0.45, 1.0);

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
	// Distort UV with overlapping waves
	float wave1 = sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
	float wave2 = sin(UV.x * wave_frequency * 1.7 - TIME * wave_speed * 0.8) * wave_amplitude * 0.5;
	vec2 uv_warp = UV + vec2(wave1 + wave2, wave1 * 0.5);

	// Depth gradient: darker at bottom
	float depth = UV.y;
	vec4 base_color = mix(water_color, deep_color, depth * 0.7);

	// Foam at surface (top of texture)
	float foam_noise = noise(uv_warp * 10.0 + TIME * 0.3);
	float foam_mask  = step(foam_threshold, foam_noise) * smoothstep(0.2, 0.0, UV.y);

	// Shimmer highlights
	float shimmer = noise(uv_warp * 14.0 + vec2(TIME * 0.6, 0.0));
	float highlight = pow(shimmer, 4.0) * 0.4 * (1.0 - depth);

	vec4 final = mix(base_color, foam_color, foam_mask);
	final.rgb += highlight;
	COLOR = final;
}

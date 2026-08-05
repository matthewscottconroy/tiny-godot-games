shader_type canvas_item;

uniform float time_val : hint_range(0.0, 1000.0) = 0.0;
uniform int preset = 0; // 0=curl, 1=radial, 2=swarm

const int NUM_PARTICLES = 80;
const float TWO_PI = 6.28318530718;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 curl_field(vec2 pos, float t) {
	float scale = 3.0;
	vec2 p = pos * scale;
	float nx = sin(p.y + t * 0.7) + sin(p.x * 0.5 + t * 0.4);
	float ny = cos(p.x + t * 0.5) + cos(p.y * 0.7 - t * 0.3);
	return normalize(vec2(ny, -nx)) * 0.18;
}

vec2 radial_field(vec2 pos, float seed, float t) {
	float angle = seed * TWO_PI + t * (0.4 + seed * 0.6);
	float r = 0.25 + seed * 0.2 + sin(t * 0.8 + seed * 3.0) * 0.05;
	return vec2(0.5) + vec2(cos(angle), sin(angle)) * r;
}

vec2 swarm_field(vec2 pos, float seed, float t) {
	vec2 target = vec2(0.5 + sin(t * 0.4 + seed) * 0.15,
					   0.5 + cos(t * 0.3 - seed) * 0.12);
	vec2 diff = target - pos;
	float dist = length(diff) + 0.001;
	vec2 toward = diff / dist * 0.012;
	float wobble_x = sin(t * 1.2 + seed * 7.3) * 0.006;
	float wobble_y = cos(t * 0.9 + seed * 5.1) * 0.006;
	return pos + toward + vec2(wobble_x, wobble_y);
}

void fragment() {
	vec3 col = vec3(0.04, 0.02, 0.08);
	float glow_acc = 0.0;
	vec3 tint_acc = vec3(0.0);

	for (int i = 0; i < NUM_PARTICLES; i++) {
		float seed = float(i) / float(NUM_PARTICLES);
		float phase = seed * TWO_PI;
		float speed = 0.5 + hash11(seed * 17.3) * 0.8;
		vec2 init_pos = vec2(hash21(vec2(seed, 0.1)), hash21(vec2(seed, 0.9)));

		vec2 ppos;
		if (preset == 0) {
			float t2 = time_val * speed * 0.4;
			ppos = init_pos + curl_field(init_pos + vec2(t2 * 0.1, t2 * 0.07), t2);
			ppos = fract(ppos + 1.0);
		} else if (preset == 1) {
			ppos = radial_field(init_pos, seed, time_val * speed * 0.6);
		} else {
			ppos = swarm_field(init_pos + vec2(
				sin(time_val * speed * 0.3 + phase) * 0.08,
				cos(time_val * speed * 0.25 + phase) * 0.08),
				seed, time_val * speed * 0.5);
		}

		vec2 diff = UV - ppos;
		float dist = length(diff);
		float brightness = 0.004 / (dist * dist + 0.0002);
		brightness = clamp(brightness, 0.0, 1.0);

		float hue = seed + time_val * 0.04 * speed;
		float h = fract(hue) * 6.0;
		vec3 particle_color;
		if (preset == 0) {
			particle_color = mix(vec3(0.2, 0.5, 1.0), vec3(0.8, 0.3, 1.0), seed);
		} else if (preset == 1) {
			particle_color = vec3(0.5 + 0.5 * sin(h), 0.5 + 0.5 * sin(h + 2.094), 0.5 + 0.5 * sin(h + 4.189));
		} else {
			particle_color = mix(vec3(1.0, 0.6, 0.1), vec3(0.1, 0.9, 0.5), seed);
		}

		glow_acc += brightness;
		tint_acc += particle_color * brightness;
	}

	if (glow_acc > 0.001) {
		col += tint_acc / glow_acc * glow_acc;
	}

	col = clamp(col, 0.0, 1.0);
	col = pow(col, vec3(0.85));
	COLOR = vec4(col, 1.0);
}

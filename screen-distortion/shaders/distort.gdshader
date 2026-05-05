shader_type canvas_item;

uniform float strength  : hint_range(0.0, 0.08) = 0.025;
uniform float wave_freq : hint_range(1.0, 20.0) = 7.0;
uniform float speed     : hint_range(0.0, 5.0)  = 1.8;

void fragment() {
	vec2 uv = UV;
	uv.x += sin(uv.y * wave_freq * PI + TIME * speed) * strength;
	uv.y += cos(uv.x * wave_freq * PI + TIME * speed * 1.3) * strength * 0.6;
	uv = clamp(uv, vec2(0.0), vec2(1.0));
	COLOR = texture(TEXTURE, uv);
}

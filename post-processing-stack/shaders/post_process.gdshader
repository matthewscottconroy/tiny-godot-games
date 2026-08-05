shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform bool vignette_on = true;
uniform bool chromatic_on = true;
uniform bool grade_on = true;
uniform float vignette_str : hint_range(0.0, 3.0) = 1.4;
uniform float chroma_str : hint_range(0.0, 0.02) = 0.006;
uniform vec4 grade_tint : source_color = vec4(1.05, 0.95, 0.88, 1.0);
uniform float gamma : hint_range(0.5, 2.0) = 0.94;

void fragment() {
	vec2 uv = SCREEN_UV;

	vec4 col;
	if (chromatic_on) {
		vec2 offset = (uv - 0.5) * chroma_str;
		float r = texture(SCREEN_TEXTURE, uv + offset).r;
		float g = texture(SCREEN_TEXTURE, uv).g;
		float b = texture(SCREEN_TEXTURE, uv - offset).b;
		col = vec4(r, g, b, 1.0);
	} else {
		col = texture(SCREEN_TEXTURE, uv);
	}

	if (grade_on) {
		col.rgb *= grade_tint.rgb;
		col.rgb = pow(max(col.rgb, vec3(0.0)), vec3(gamma));
	}

	if (vignette_on) {
		vec2 center = uv - 0.5;
		float vig = 1.0 - dot(center, center) * vignette_str * 3.8;
		col.rgb *= clamp(vig, 0.0, 1.0);
	}

	COLOR = col;
}

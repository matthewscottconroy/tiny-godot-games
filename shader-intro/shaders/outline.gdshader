shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_size : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 texel = outline_size / vec2(textureSize(TEXTURE, 0));

	float alpha = col.a;
	alpha = max(alpha, texture(TEXTURE, UV + vec2( texel.x, 0.0)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(-texel.x, 0.0)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0,  texel.y)).a);
	alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, -texel.y)).a);

	vec4 border = vec4(outline_color.rgb, alpha * outline_color.a);
	COLOR = mix(border, col, col.a);
}

shader_type canvas_item;

// pixel_size: larger = more blocky
uniform float pixel_size : hint_range(1.0, 32.0) = 8.0;

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 pixels   = floor(UV * tex_size / pixel_size) * pixel_size;
	vec2 snapped  = pixels / tex_size;
	COLOR = texture(TEXTURE, snapped);
}

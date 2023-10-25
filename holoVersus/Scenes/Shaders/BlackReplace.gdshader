shader_type canvas_item;

uniform float replace_r;
uniform float replace_g;
uniform float replace_b;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    float value = (COLOR.r + COLOR.g + COLOR.b) / 3.0 + (1.0 - COLOR.a);
	value = ceil(value);
	vec4 new_color = vec4(replace_r, replace_g, replace_b, 1.0);
    COLOR = mix(new_color, texture(TEXTURE, UV), value);
}
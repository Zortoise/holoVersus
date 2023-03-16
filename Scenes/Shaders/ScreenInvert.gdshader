shader_type canvas_item;

void fragment() {
    vec4 c = textureLod( SCREEN_TEXTURE, SCREEN_UV, 0.0).rgba;
	c.r = 1.0 - c.r;
	c.g = 1.0 - c.g;
	c.b = 1.0 - c.b;
	c.a = texture(TEXTURE, UV).a;
	COLOR.rgba = c;
}
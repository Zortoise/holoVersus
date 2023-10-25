shader_type canvas_item;

uniform vec2 Direction = vec2(1.0, 0.0);
uniform float Speed = 0.08;
uniform float Start_Time = 0.0;

uniform float time = 0.0;

void fragment()
{
	COLOR = texture(TEXTURE, UV + (Direction * time * Speed) + (Direction * Start_Time * Speed));
}
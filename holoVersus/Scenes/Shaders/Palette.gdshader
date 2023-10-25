shader_type canvas_item;

uniform sampler2D swap;

void fragment(){
  COLOR = mix(texture(TEXTURE, UV), texture(swap, vec2(texture(TEXTURE, UV).r, 0)), texture(TEXTURE, UV).a * texture(swap, vec2(texture(TEXTURE, UV).r, 0)).a);
}
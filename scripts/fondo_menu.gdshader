shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear_mipmap;
void fragment() {
	vec3 fondo = textureLod(pantalla, SCREEN_UV, 2.0).rgb;
	COLOR = vec4(mix(fondo, vec3(0.025, 0.065, 0.075), 0.48), 1.0);
}

shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear_mipmap;
void fragment() {
	vec3 fondo = textureLod(pantalla, SCREEN_UV, 2.5).rgb;
	float rosa = exp(-length((SCREEN_UV - vec2(0.08, 0.22)) * vec2(1.2, 1.0)) * 4.0);
	float oro = exp(-length((SCREEN_UV - vec2(0.95, 0.78)) * vec2(1.2, 1.0)) * 4.5);
	float vineta = smoothstep(0.25, 0.8, length(SCREEN_UV - vec2(0.5)));
	vec3 base = mix(fondo, vec3(0.015, 0.035, 0.023), 0.64 + vineta * 0.18);
	base += vec3(0.13, 0.018, 0.075) * rosa + vec3(0.075, 0.055, 0.012) * oro;
	COLOR = vec4(base, 1.0);
}

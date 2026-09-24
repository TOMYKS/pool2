shader_type spatial;

uniform sampler2D insignia : source_color, filter_linear_mipmap, repeat_disable;
varying vec3 posicion_local;

void vertex() {
	posicion_local = VERTEX;
}

void fragment() {
	// Dos insignias opuestas, siguiendo la curvatura de la esfera.
	// Invertir X detrás mantiene el signo legible, sin reflejarlo.
	float lado = posicion_local.z >= 0.0 ? 1.0 : -1.0;
	vec2 uv_insignia = vec2(posicion_local.x * lado, -posicion_local.y) / 0.31 + 0.5;
	vec4 marca = texture(insignia, uv_insignia);
	float cara = step(0.135, abs(posicion_local.z));
	float dentro = step(0.0, uv_insignia.x) * step(uv_insignia.x, 1.0)
		* step(0.0, uv_insignia.y) * step(uv_insignia.y, 1.0);
	ALBEDO = mix(vec3(0.012, 0.015, 0.022), marca.rgb, marca.a * cara * dentro);
	METALLIC = 0.05;
	ROUGHNESS = 0.19;
	SPECULAR = 0.65;
}

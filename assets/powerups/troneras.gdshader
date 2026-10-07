shader_type spatial;

varying vec3 posicion_local;
varying vec3 normal_local;

void vertex() {
	posicion_local = VERTEX;
	normal_local = NORMAL;
}

void fragment() {
	// Todo el dibujo está en una sola superficie: no hay caras superpuestas.
	vec3 violeta = vec3(0.24, 0.055, 0.38);
	vec3 oro = vec3(1.0, 0.66, 0.12);
	float dorado;
	if (normal_local.y > 0.5) {
		// Marco en la cara superior, con centro violeta.
		dorado = max(step(0.62, abs(posicion_local.x)), step(0.08, abs(posicion_local.z)));
	} else {
		dorado = step(0.20, posicion_local.y);
	}
	if (abs(normal_local.z) > 0.5) {
		// Una única X pintada, suavizada según su tamaño en pantalla.
		vec2 p = posicion_local.xy;
		float diagonal = abs(abs(p.x) - abs(p.y)) * 0.70710678;
		float distancia = max(diagonal - 0.012, max(abs(p.x), abs(p.y)) - 0.12);
		float suavizado = max(fwidth(distancia), 0.0001);
		dorado = max(dorado, 1.0 - smoothstep(-suavizado, suavizado, distancia));
	}
	ALBEDO = mix(violeta, oro, dorado);
	METALLIC = mix(0.45, 0.65, dorado);
	ROUGHNESS = 0.35;
	EMISSION = vec3(0.4, 0.16, 0.015) * dorado;
}

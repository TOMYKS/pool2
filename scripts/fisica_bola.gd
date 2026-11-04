extends RefCounted

const MAX_GIRO_VERTICAL := 24.0 # rad/s
const FRENO_GIRO_MOVIENDO := 4.0 # rad/s²
const FRENO_GIRO_QUIETO := 24.0 # rad/s²
const FRENO_GIRO_HORIZONTAL_QUIETO := 6.0 # rad/s²
const UMBRAL_ROCE_RAPIDO := 2.0 # unidades/s; por debajo manda la rodadura.

static func integrar(state: PhysicsDirectBodyState3D, ascenso: float, rodadura: float, roce_velocidad: float = 0.0) -> void:
	var velocidad := state.linear_velocity
	# Seguridad común para todas las bolas; los tiros normales no alcanzan el tope.
	velocidad = velocidad.limit_length(45.0)
	if ascenso > 0.0:
		velocidad.y = minf(velocidad.y, ascenso)
	# Resistencia del paño: desaceleración constante, solo con apoyo real.
	# No frenar vuelos, contactos con otras bolas ni caídas en troneras.
	for i in range(state.get_contact_count()):
		# "local" identifica nuestro cuerpo; la normal ya viene en ejes globales.
		var normal := state.get_contact_local_normal(i)
		if normal.y > 0.9 and state.get_contact_collider_object(i) is StaticBody3D:
			var horizontal := Vector3(velocidad.x, 0, velocidad.z)
			var rapidez := horizontal.length()
			var giro := state.angular_velocity
			# El giro vertical no produce rodadura: disiparlo por separado sin
			# aumentar el frenado del avance ni eliminar el backspin/topspin.
			var peso_lento := 1.0 - smoothstep(0.06, 1.0, rapidez)
			giro.y = move_toward(clampf(giro.y, -MAX_GIRO_VERTICAL, MAX_GIRO_VERTICAL), 0.0, lerpf(FRENO_GIRO_MOVIENDO, FRENO_GIRO_QUIETO, peso_lento) * state.step)
			if rapidez < 0.06:
				var residual := Vector2(giro.x, giro.z).move_toward(Vector2.ZERO, FRENO_GIRO_HORIZONTAL_QUIETO * state.step)
				giro.x = residual.x
				giro.z = residual.y
			# El roce adicional crece con la rapidez, sin apagar los tiros finos.
			var frenado := rodadura + roce_velocidad * maxf(0.0, rapidez - UMBRAL_ROCE_RAPIDO)
			horizontal = horizontal.move_toward(Vector3.ZERO, frenado * state.step)
			# Frenar también el giro de rodadura: de otro modo el contacto
			# vuelve a convertir ese giro en avance y deja un arrastre residual.
			if rapidez > 0.001:
				var proporcion := horizontal.length() / rapidez
				giro.x *= proporcion
				giro.z *= proporcion
			state.angular_velocity = giro
			velocidad.x = horizontal.x
			velocidad.z = horizontal.z
			break
	state.linear_velocity = velocidad

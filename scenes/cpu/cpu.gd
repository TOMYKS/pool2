extends Node

# Cavernícola: bola válida más cercana + tronera cercana + golpe con error.
# No busca rebotes ni simula trayectorias; los obstáculos pueden hacerla fallar.
# Ajustar acá. Ejemplos (probabilidad, grados, fuerza):
# Fácil: 0.85, 18.0, 0.55 / Normal: 0.45, 8.0, 0.25 / Difícil: 0.15, 2.0, 0.10.
var probabilidad_error := 0.40
var error_angulo_grados := 5.0
var error_fuerza := 0.10
var demora := 1.0
var distancia_colocacion := 1.0 # Separación detrás de la bola objetivo.
var variacion_colocacion := 0.25 # Variación máxima en metros alrededor del punto ideal.
var espera := 0.1
var azar := RandomNumberGenerator.new()
@onready var partida = get_parent()
@onready var sala = partida.get_parent()


func _ready() -> void:
	azar.randomize()


func _physics_process(delta: float) -> void:
	if partida.configurando or partida.terminada or partida.reiniciando or not partida.es_turno_cpu() or partida.reglas.en_tiro or sala.is_waiting_for_ball or sala.camara_en_transicion():
		espera = 0.0
		return
	if not sala.todas_las_bolas_detenidas():
		espera = 0.0
		return
	espera += delta
	if espera < demora:
		return
	espera = 0.0
	partida._control_camara(false)
	sala.cambiar_camara(sala.camera_mesa)
	if partida.bola_en_mano:
		_colocar_blanca()
		return
	var objetivo := elegir_objetivo()
	if objetivo == null:
		return
	var tiro := calcular_tiro(objetivo)
	disparar(tiro.direccion, tiro.fuerza)


func elegir_objetivo() -> RigidBody3D:
	var reglas = partida.reglas
	var abiertas: bool = reglas.grupos[1] == 0
	var pendientes: Array[int] = reglas.pendientes(2)
	var elegida: RigidBody3D
	var distancia := INF
	for bola in get_tree().get_nodes_in_group("bolas_color"):
		if bola.is_queued_for_deletion():
			continue
		var numero := int(bola.get_meta("numero", 0))
		var mortal := bool(bola.get_meta("ocho_mortal", false))
		var valida := false
		if abiertas:
			valida = numero != 8 and not mortal
		elif pendientes.is_empty():
			valida = numero == 8 or mortal
		else:
			valida = pendientes.has(numero) and not mortal
		if not valida:
			continue
		var d: float = sala.ball.global_position.distance_squared_to(bola.global_position)
		if d < distancia:
			distancia = d
			elegida = bola
	return elegida


func _tronera_cercana(posicion: Vector3) -> Vector3:
	var tronera := Vector3.ZERO
	var distancia := INF
	for x in [-4.65, 0.0, 4.65]:
		for z in [-2.65, 2.65]:
			var punto: Vector3 = sala.to_global(Vector3(x, 0, z))
			punto.y = posicion.y
			var d := posicion.distance_squared_to(punto)
			if d < distancia:
				distancia = d
				tronera = punto
	return tronera


func calcular_tiro(objetivo: RigidBody3D) -> Dictionary:
	var posicion := objetivo.global_position
	var tronera := _tronera_cercana(posicion)
	# Golpear detrás de la bola para empujarla hacia la tronera elegida.
	var contacto: Vector3 = posicion - posicion.direction_to(tronera) * (partida._radio(objetivo) + sala.ball_radius)
	var direccion: Vector3 = contacto - sala.ball.global_position
	direccion.y = 0
	if direccion.length_squared() < 0.0001:
		direccion = Vector3.RIGHT
	var potencia := clampf(2.5 + direccion.length() * 0.8 + posicion.distance_to(tronera) * 0.6, 2.5, 12.0)
	return aplicar_error(direccion.normalized(), potencia)


func aplicar_error(direccion: Vector3, potencia: float) -> Dictionary:
	if azar.randf() < probabilidad_error:
		direccion = direccion.rotated(Vector3.UP, deg_to_rad(azar.randf_range(-error_angulo_grados, error_angulo_grados)))
		potencia *= 1.0 + azar.randf_range(-error_fuerza, error_fuerza)
	return {"direccion": direccion, "fuerza": clampf(potencia, 0.5, 20.0)}


func _colocar_blanca() -> void:
	var objetivo := elegir_objetivo()
	if objetivo == null:
		return
	var hacia_tronera := objetivo.global_position.direction_to(_tronera_cercana(objetivo.global_position))
	var separacion: float = maxf(distancia_colocacion, partida._radio(objetivo) + sala.ball_radius + variacion_colocacion + 0.1)
	var ideal := objetivo.global_position - hacia_tronera * separacion
	ideal.y = sala.to_global(Vector3(0, partida.ALTURA_PANO + sala.ball_radius + 0.01, 0)).y
	# Cerca y detrás del objetivo, para empujarlo hacia su tronera.
	for intento in range(24):
		var punto := ideal + Vector3(azar.randf_range(-variacion_colocacion, variacion_colocacion), 0, azar.randf_range(-variacion_colocacion, variacion_colocacion))
		if partida.posicion_valida(punto) and _camino_libre(punto, objetivo):
			partida.colocar_blanca(punto)
			return
	# Si el punto ideal está ocupado, buscar el lugar libre más cercano a él.
	var mejor: Variant = null
	var mejor_puntaje := INF
	for x in range(-8, 9):
		for z in range(-4, 5):
			var punto: Vector3 = sala.to_global(Vector3(x * 0.5 + azar.randf_range(-0.1, 0.1), partida.ALTURA_PANO + sala.ball_radius + 0.01, z * 0.5 + azar.randf_range(-0.1, 0.1)))
			if partida.posicion_valida(punto):
				var puntaje := punto.distance_squared_to(ideal) + (0.0 if _camino_libre(punto, objetivo) else 100.0)
				if puntaje < mejor_puntaje:
					mejor = punto
					mejor_puntaje = puntaje
	if mejor != null:
		partida.colocar_blanca(mejor)


func _camino_libre(desde: Vector3, objetivo: RigidBody3D) -> bool:
	var consulta := PhysicsRayQueryParameters3D.create(desde, objetivo.global_position, 3)
	consulta.exclude = [sala.ball.get_rid(), sala.taco.get_rid()]
	var choque: Dictionary = sala.get_world_3d().direct_space_state.intersect_ray(consulta)
	return choque.is_empty() or choque.collider == objetivo


func disparar(direccion: Vector3, fuerza: float) -> void:
	if not partida.es_turno_cpu() or not partida.puede_apuntar() or sala.is_waiting_for_ball:
		return
	sala.is_hitting_mode = false
	sala.marker.hide()
	sala.taco.hide()
	sala.taco.global_position = Vector3(0, -1, 0)
	sala.ball.sleeping = false
	sala.ball.apply_central_impulse(direccion * clampf(fuerza, 5.5, 20.0))
	sala.sonido_taco.volume_db = lerpf(-14.0, 0.0, inverse_lerp(5.5, 20.0, fuerza))
	sala.sonido_taco.play()
	sala.tiro_iniciado.emit()
	sala.is_waiting_for_ball = true
	sala.time_since_hit = 0.0
	sala._tiempo_en_reposo = 0.0
	sala.cambiar_camara(sala.camera_mesa)

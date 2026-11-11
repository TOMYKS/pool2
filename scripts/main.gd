extends Node3D

signal tiro_iniciado
signal tiro_finalizado

const ReposoBola = preload("res://scripts/reposo_bola.gd")

@export_group("Referencias de escena")
@export var pivote: Node3D
@export var camera: Camera3D
@export var camera_mesa: Camera3D
@export var marker: MeshInstance3D
@export var taco: AnimatableBody3D
@export var ball: RigidBody3D
@onready var sonido_taco = $Audio/SonidoTaco
@onready var sonido_pocket = $Audio/SonidoPocket
@onready var partida = $Partida

var time_since_hit: float = 0.0
var _tiempo_en_reposo: float = 0.0
var impact_point_global: Vector3
var _direccion_apuntada := Vector3.ZERO
var _punta_saque: RigidBody3D
var is_hitting_mode: bool = false
# El collider de la punta sobresale 0.114 m del origen del taco.
@export_group("Taco y potencia")
@export var cue_initial_distance: float = 0.15
@export var cue_max_pullback: float = 1.35
@export var cue_mouse_travel: float = 0.01
@export var cue_stop_seconds: float = 0.16
@export var cue_power_curve: float = 1.5
@export var cue_max_force: float = 30.0
## Pequeñas diferencias entre armados, conservando la composición manual.
@export_group("Armado y saque")
@export_range(0.0, 0.005, 0.0005) var variacion_triangulo: float = 0.0
@export_range(0.0, 1.0, 0.1) var angulo_triangulo: float = 0.3
## Separación adicional de 3.5 % para evitar contactos especulativos del rack.
@export_range(1.0, 1.05, 0.001) var separacion_triangulo: float = 1.035
## Solo en el saque: ajusta el tramo alto de potencia. 0 lo desactiva.
@export_range(0.0, 65.0, 0.5) var saque_max_force: float = 48.0
var is_waiting_for_ball: bool = false
var _recorrido_golpe: float = 0.0
var _pausa_golpe: float = 0.0
var _golpe_armado: bool = false
var _material_potencia: StandardMaterial3D

## Tope de ascenso de TODAS las bolas, incluida la blanca, en m/s. 0 lo desactiva.
## Se conserva el nombre anterior para respetar los valores guardados en Sala.
## Solo afecta Y positiva; no modifica potencia, giro, rebote horizontal ni caídas.
@export_group("Fisica de las bolas")
@export_range(0.0, 5.0, 0.1) var velocidad_vertical_maxima_color: float = 0.0
## Resistencia de rodadura en unidades de escena/s², común a todas las bolas.
@export var usar_rodadura_del_perfil: bool = true
@export_range(0.0, 1.5, 0.001) var desaceleracion_rodadura: float = 0.418514221
## Roce extra por encima de 2 m/s físicos (convertidos a la escala de la mesa).
@export_range(0.0, 2.0, 0.1) var roce_velocidad: float = 0.0

## Duración del viaje entre la cámara de apuntado y la vista general (0 = corte).
@export_group("Transiciones de camara")
@export_range(0.0, 3.0, 0.05) var camera_transition_seconds: float = 0.65
var _camara_viaje: Camera3D
var _destino_camara: Camera3D
var _tween_camara: Tween


func camara_en_transicion() -> bool:
	return _tween_camara != null and _tween_camara.is_running()


func cambiar_camara(destino: Camera3D) -> void:
	if camara_en_transicion() and _destino_camara == destino:
		return
	var actual := get_viewport().get_camera_3d()
	if actual == destino:
		return
	if _tween_camara != null:
		_tween_camara.kill()
	_destino_camara = destino
	if actual == null or camera_transition_seconds <= 0.0:
		destino.make_current()
		return
	if destino == camera:
		pivote.global_position = ball.global_position
	var origen := actual.global_transform
	var fov_origen := actual.fov
	if _camara_viaje == null:
		_camara_viaje = Camera3D.new()
		_camara_viaje.name = "CamaraTransicion"
		$Camaras.add_child(_camara_viaje)
	_camara_viaje.global_transform = origen
	_camara_viaje.fov = fov_origen
	_camara_viaje.near = destino.near
	_camara_viaje.far = destino.far
	_camara_viaje.cull_mask = destino.cull_mask
	_camara_viaje.environment = destino.environment
	_camara_viaje.make_current()
	# Trayecto recto como una cámara en cable, con arranque y frenado suaves.
	_tween_camara = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_camara.tween_method(func(peso: float):
		_camara_viaje.global_transform = origen.interpolate_with(destino.global_transform, peso)
		_camara_viaje.fov = lerpf(fov_origen, destino.fov, peso)
	, 0.0, 1.0, camera_transition_seconds)
	_tween_camara.tween_callback(destino.make_current)

# --- CONFIGURACIN DE SPIN (Arcade) ---
## Radio de la bola (debe coincidir con el CollisionShape3D SphereShape3D)
@export_group("Efecto de la blanca")
@export var ball_radius: float = 0.14
## Torque mÃ¡ximo permitido (clamp) para evitar spins absurdos
@export var max_torque: float = 3.0

func _ready() -> void:
	ball.body_entered.connect(_contacto_saque)
	if usar_rodadura_del_perfil:
		var f := preload("res://scripts/fisica_bola.gd")
		desaceleracion_rodadura = f.PERFIL.friccion_rodadura * f.gravedad()
	preload("res://scripts/fisica_bola.gd").preparar_mesa($Mesa)
	var azar_triangulo := RandomNumberGenerator.new()
	azar_triangulo.randomize()
	preload("res://scripts/armado_triangulo.gd").preparar(get_tree().get_nodes_in_group("bolas_color"), variacion_triangulo, angulo_triangulo, azar_triangulo, separacion_triangulo)
	for bola in [ball] + get_tree().get_nodes_in_group("bolas_color"):
		bola.velocidad_vertical_maxima = velocidad_vertical_maxima_color
		bola.desaceleracion_rodadura = desaceleracion_rodadura
		bola.roce_velocidad = roce_velocidad
	_material_potencia = StandardMaterial3D.new()
	_material_potencia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = _material_potencia
	marker.hide()
	taco.hide()
	taco.global_position = Vector3(0, -1, 0)
	# El taco consulta contactos, pero las bolas no reciben empujes del cuerpo.
	# El único impulso del golpe es el que aplicamos explícitamente abajo.
	taco.collision_layer = 0


func cancelar_apuntado() -> void:
	_direccion_apuntada = Vector3.ZERO
	is_hitting_mode = false
	_golpe_armado = false
	_recorrido_golpe = 0.0
	_pausa_golpe = 0.0
	marker.hide()
	taco.hide()
	taco.global_position = Vector3(0, -1, 0)

func _unhandled_input(event):
	if not partida.permite_input_humano() or camara_en_transicion():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			cancelar_apuntado()
			if partida.bola_en_mano:
				partida.solicitar_colocacion(event.position)
			else:
				shoot_raycast(event.position)
		else:
			cancelar_apuntado()
			
func shoot_raycast(mouse_pos: Vector2):
	if camara_en_transicion() or is_waiting_for_ball or not partida.puede_apuntar() or not partida.permite_input_humano():
		return
	if pivote.is_dragging_camera:
		return
	var space_state = get_world_3d().direct_space_state
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space_state.intersect_ray(query)
	
	# Si el rayo cho con algo, y ese algo es nuestra bola
	if result and result.collider == ball:
		var fisica = preload("res://scripts/fisica_bola.gd")
		var seleccion: Dictionary = fisica.seleccionar_impacto(origin, camera.project_ray_normal(mouse_pos), ball.global_position, fisica.radio_de(ball))
		if seleccion.is_empty():
			return
		impact_point_global = seleccion.punto
		_direccion_apuntada = seleccion.direccion
		marker.global_position = result.position
		marker.visible = true
		
		# Preparamos el palo
		setup_cue_stick()

func setup_cue_stick():
	# 2. Calculamos la posicn deseada
	var pos_camara = camera.global_position
	var direccion := _direccion_apuntada
	if direccion.is_zero_approx():
		direccion = Vector3(ball.global_position.x - pos_camara.x, 0, ball.global_position.z - pos_camara.z).normalized()
	
	var distancia_retiro = cue_initial_distance
	var posicion_final = impact_point_global - (direccion * distancia_retiro)
	posicion_final.y = impact_point_global.y

	# 3. Forzamos el teletransporte alterando el Transform directamente
	taco.global_transform.origin = posicion_final
	taco.visible = true
	
	# 4. Apuntamos
	taco.look_at(impact_point_global, Vector3.UP)
	taco.get_node("Visual").preparar(impact_point_global, cue_initial_distance + cue_max_pullback)
	
	is_hitting_mode = true
	_golpe_armado = false
	_recorrido_golpe = 0.0
	_pausa_golpe = 0.0
	_actualizar_indicador_potencia()
func _input(event):
	# Procesar la cancelación incluso si una interfaz consume el clic.
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) or (event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			cancelar_apuntado()
	if not partida.permite_input_humano():
		return
	# Si ya hicimos clic en la bola, el movimiento del ratn mueve el palo
	if is_hitting_mode and event is InputEventMouseMotion:
		var mouse_movement = event.relative.y
		var forward_vector = -taco.global_transform.basis.z
		
		# move_and_collide devuelve los datos de la colisn si choca con algo
		# Recorrido independiente de la potencia: retirar el taco no lo saca de vista.
		var distancia_actual: float = (impact_point_global - taco.global_position).dot(forward_vector)
		var retroceso_disponible: float = maxf(0.0, cue_initial_distance + cue_max_pullback - distancia_actual)
		var avance: float = maxf(-mouse_movement * cue_mouse_travel, -retroceso_disponible)
		# Un avance inicial nunca puede tocar la bola: primero hay que retirar
		# el taco, aunque sea mínimamente. La pausa no desarma ese retroceso.
		if not _golpe_armado and avance >= 0.0:
			return
		var motion = forward_vector * avance
		var collision = taco.move_and_collide(motion, true)
		taco.global_position += collision.get_travel() if collision else motion
		taco.get_node("Visual").actualizar()
		# Contar solo el recorrido real hasta el contacto, no el mouse sobrante.
		var recorrido_real: float = collision.get_travel().dot(forward_vector) if collision else avance
		if mouse_movement > 0.0:
			if recorrido_real < 0.0:
				_golpe_armado = true
			_recorrido_golpe = 0.0
		elif recorrido_real > 0.0:
			_recorrido_golpe += recorrido_real
			_pausa_golpe = 0.0
		_actualizar_indicador_potencia()
		
		# Si chocamos con la bola, terminamos el modo de golpe
		if collision and collision.get_collider() == ball:
			is_hitting_mode = false
			_golpe_armado = false
			marker.visible = false
			taco.visible = false # Ocultamos el palo
			
			# ============================================			# ============================================
			# GOLPE CON CONTACTO E INCLINACION
			# ============================================
			
			# 1. DIRECCIÓN DEL GOLPE
			var hit_direction: Vector3 = -taco.global_transform.basis.z.normalized()
			
			var raw_force := ajustar_fuerza_tiro(_potencia_del_recorrido())
			var hit_force := aplicar_golpe(hit_direction, raw_force, impact_point_global)
			var peso_golpe = clampf(hit_force / _limite_potencia_actual(), 0.0, 1.0)
			
			# Rango muy cerrado: de -8.0 dB (suave) a 0.0 dB (fuerte). Siempre se escuchará.
			sonido_taco.volume_db = lerp(-14.0, 0.0, peso_golpe)
			sonido_taco.play()
			tiro_iniciado.emit()


						# 2. CAMBIO DE CMARA A LA MESA
			is_waiting_for_ball = true
			time_since_hit = 0.0
			if camera_mesa:
				cambiar_camara(camera_mesa)
				is_waiting_for_ball = true 
				taco.global_position = Vector3(0,-1,0)
				time_since_hit = 0.0 #
func _potencia_del_recorrido() -> float:
	return _potencia_para_recorrido(_recorrido_golpe)


func ajustar_fuerza_tiro(fuerza: float) -> float:
	if not partida.reglas.saque or saque_max_force <= 0.0:
		return fuerza
	var maximo := saque_max_force
	# Conservar intacto el 70 % inferior del control de potencia. Por encima,
	# ajustar suavemente hasta el máximo del saque.
	var umbral := minf(cue_max_force * 0.7, maximo)
	if fuerza <= umbral:
		return fuerza
	var peso := clampf((fuerza - umbral) / maxf(cue_max_force - umbral, 0.001), 0.0, 1.0)
	return lerpf(umbral, maximo, peso)


func _limite_potencia_actual() -> float:
	return saque_max_force if partida.reglas.saque and saque_max_force > 0.0 else cue_max_force


func _potencia_para_recorrido(recorrido: float) -> float:
	# Curva suave: deja más recorrido disponible para tiros bajos y medios.
	var proporcion := clampf(recorrido / maxf(cue_max_pullback, 0.01), 0.0, 1.0)
	return cue_max_force * pow(proporcion, cue_power_curve)


func _actualizar_indicador_potencia() -> void:
	# Prever la potencia al llegar a la bola, no solo el avance ya recorrido.
	var direccion := -taco.global_basis.z.normalized()
	var restante := maxf(0.0, (impact_point_global - taco.global_position).dot(direccion) - 0.114)
	var potencia := ajustar_fuerza_tiro(_potencia_para_recorrido(_recorrido_golpe + restante))
	var datos := datos_golpe(direccion, potencia, impact_point_global)
	potencia = (datos.impulso as Vector3).length()
	var peso := clampf(potencia / _limite_potencia_actual(), 0.0, 1.0)
	var verde := Color(0.1, 1.0, 0.15)
	var amarillo := Color(1.0, 0.9, 0.0)
	var rojo := Color(1.0, 0.08, 0.02)
	_material_potencia.albedo_color = verde.lerp(amarillo, peso * 2.0) if peso <= 0.5 else amarillo.lerp(rojo, (peso - 0.5) * 2.0)


func _process(delta):
	if is_hitting_mode:
		_pausa_golpe += delta
		if _pausa_golpe >= cue_stop_seconds:
			_recorrido_golpe = 0.0
		_actualizar_indicador_potencia()
	# El tiro incluye los movimientos causados por el vencimiento del poder.
	if is_waiting_for_ball:
		time_since_hit += delta
		if time_since_hit <= 0.5 or not todas_las_bolas_detenidas():
			_tiempo_en_reposo = 0.0
			return
		# No decidir el turno por un único frame de velocidad casi nula.
		_tiempo_en_reposo += delta
		if _tiempo_en_reposo < 0.3:
			return
		# El rack puede despertarse por contactos mínimos entre bolas vecinas.
		# Tras reposo estable, eliminar ese residuo antes de resolver el turno.
		for bola in [ball] + get_tree().get_nodes_in_group("bolas_color"):
			if not bola.is_queued_for_deletion() and not bola.freeze:
				bola.linear_velocity = Vector3.ZERO
				bola.angular_velocity = Vector3.ZERO
				bola.sleeping = true
		var poderes = get_node_or_null("Powerups")
		if poderes != null and poderes.preparar_fin_tiro():
			# Encoger bolas o quitar una pared puede liberar una caída.
			# Las reglas siguen registrando el MISMO tiro y jugador.
			time_since_hit = 0.0
			_tiempo_en_reposo = 0.0
			return
		is_waiting_for_ball = false
		_tiempo_en_reposo = 0.0
		partida.finalizar_tiro()
		tiro_finalizado.emit()
	else:
		_tiempo_en_reposo = 0.0
func _on_limites_mesa_body_entered(body):
	partida.registrar_caida(body)
func todas_las_bolas_detenidas() -> bool:
	# 1. Comprobamos la blanca primero (si se mueve, ya sabemos que no debemos cambiar la cámara)
	if not ball.freeze and not ball.sleeping and not ReposoBola.puede_detenerse(ball):
		return false
		
	# 2. Obtenemos todas las bolas de color que sigan vivas en la escena
	var bolas_restantes = get_tree().get_nodes_in_group("bolas_color")
	
	# 3. Revisamos la velocidad de cada una de ellas
	for bola_color in bolas_restantes:
		if bola_color.is_queued_for_deletion() or bola_color.sleeping or bola_color.freeze:
			continue
		if not ReposoBola.puede_detenerse(bola_color):
			return false # Encontramos al menos una moviéndose, cancelamos la comprobación
			
	# Si el código llega hasta aquí, significa que absolutamente nada se está moviendo
	return true

# Usado tanto por el jugador como por la CPU.
func datos_golpe(direccion: Vector3, potencia: float, punto: Vector3) -> Dictionary:
	var fisica = preload("res://scripts/fisica_bola.gd")
	var eje: Vector3 = taco.get_node("Visual").direccion_golpe(direccion)
	return fisica.calcular_golpe(eje, punto - ball.global_position, fisica.radio_de(ball), clampf(potencia, 0.0, _limite_potencia_actual()))

func aplicar_golpe(direccion: Vector3, potencia: float, punto: Vector3) -> float:
	var datos := datos_golpe(direccion, potencia, punto)
	_punta_saque = null
	if partida.reglas.saque and (datos.impulso as Vector3).length() >= 28.0:
		for bola: RigidBody3D in get_tree().get_nodes_in_group("bolas_color"):
			if _punta_saque == null or bola.global_position.x > _punta_saque.global_position.x:
				_punta_saque = bola
	ball.freeze = false
	ball.sleeping = false
	ball.apply_impulse(datos.impulso, datos.brazo)
	ball.iniciar_comba()
	return (datos.impulso as Vector3).length()

func _contacto_saque(cuerpo: Node) -> void:
	if not is_instance_valid(_punta_saque) or not partida.reglas.en_tiro or not cuerpo.is_in_group("bolas_color"):
		return
	var es_punta := cuerpo == _punta_saque
	_punta_saque = null
	if not es_punta:
		return
	var bolas := get_tree().get_nodes_in_group("bolas_color")
	if bolas.size() == 15:
		preload("res://scripts/armado_triangulo.gd").repartir_impacto.call_deferred(bolas)

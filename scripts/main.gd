extends Node3D

signal tiro_iniciado
signal tiro_finalizado

@export var camera: Camera3D
@export var camera_mesa: Camera3D
@export var marker: MeshInstance3D
@export var taco: AnimatableBody3D
@export var ball: RigidBody3D  # <--- Esta era la l­nea que faltaba
@onready var sonido_taco = $SonidoTaco
@onready var sonido_pocket = $SonidoPocket
@onready var partida = $Partida

var time_since_hit: float = 0.0
var _tiempo_en_reposo: float = 0.0
var impact_point_global: Vector3
var is_aiming: bool = false
var is_hitting_mode: bool = false
# El collider de la punta sobresale 0.114 m del origen del taco.
@export var cue_initial_distance: float = 0.15
@export var cue_max_pullback: float = 0.9
@export var cue_mouse_travel: float = 0.01
@export var cue_stop_seconds: float = 0.16
@export var cue_power_curve: float = 1.5
var is_waiting_for_ball: bool = false
var _recorrido_golpe: float = 0.0
var _pausa_golpe: float = 0.0

# --- CONFIGURACIN DE SPIN (Arcade) ---
## Radio de la bola (debe coincidir con el CollisionShape3D SphereShape3D)
@export var ball_radius: float = 0.14
## Multiplicador base para convertir el offset normalizado en torque
@export var spin_multiplier: float = 8.0
## Torque mÃ¡ximo permitido (clamp) para evitar spins absurdos
@export var max_torque: float = 3.0

func _ready() -> void:
	marker.hide()
	taco.hide()
	taco.global_position = Vector3(0, -1, 0)

func _unhandled_input(event):
	if not partida.permite_input_humano():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if partida.bola_en_mano:
				partida.solicitar_colocacion(event.position)
			else:
				shoot_raycast(event.position)
		else:
			# Al soltar el clic, el palo deja de seguir al rat
			is_hitting_mode = false
			
func shoot_raycast(mouse_pos: Vector2):
	if is_waiting_for_ball or not partida.puede_apuntar() or not partida.permite_input_humano():
		return
	var space_state = get_world_3d().direct_space_state
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space_state.intersect_ray(query)
	
	# Si el rayo cho con algo, y ese algo es nuestra bola
	if result and result.collider == ball:
		impact_point_global = result.position
		marker.global_position = impact_point_global
		marker.visible = true
		
		# Preparamos el palo
		setup_cue_stick()

func setup_cue_stick():
	# 2. Calculamos la posicn deseada
	var pos_camara = camera.global_position
	var direccion = Vector3(impact_point_global.x - pos_camara.x, 0, impact_point_global.z - pos_camara.z).normalized()
	
	var distancia_retiro = cue_initial_distance
	var posicion_final = impact_point_global - (direccion * distancia_retiro)
	posicion_final.y = impact_point_global.y

	# 3. Forzamos el teletransporte alterando el Transform directamente
	taco.global_transform.origin = posicion_final
	taco.visible = true
	
	# 4. Apuntamos
	taco.look_at(impact_point_global, Vector3.UP)
	
	is_hitting_mode = true
	_recorrido_golpe = 0.0
	_pausa_golpe = 0.0
func _input(event):
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
		var motion = forward_vector * avance
		var collision = taco.move_and_collide(motion)
		# Contar solo el recorrido real hasta el contacto, no el mouse sobrante.
		var recorrido_real: float = collision.get_travel().dot(forward_vector) if collision else avance
		if mouse_movement > 0.0:
			_recorrido_golpe = 0.0
		elif recorrido_real > 0.0:
			_recorrido_golpe += recorrido_real
			_pausa_golpe = 0.0
		
		# Si chocamos con la bola, terminamos el modo de golpe
		if collision and collision.get_collider() == ball:
			is_hitting_mode = false
			marker.visible = false
			taco.visible = false # Ocultamos el palo
			
			# ============================================			# ============================================
			# SISTEMA DE GOLPE ARCADE
			# ============================================
			
			# 1. DIRECCIÓN DEL GOLPE
			var hit_direction = -taco.global_transform.basis.z.normalized()
			
			# 2. CALCULAR OFFSET DEL PUNTO DE IMPACTO (Ejes 3D)
			var offset_impacto = impact_point_global - ball.global_position
			var offset_normalizado = offset_impacto / ball_radius
			
			# 3. PROYECTAR EL OFFSET EN EJES 2D (Arriba/Abajo y Lados)
			var right_axis = hit_direction.cross(Vector3.UP).normalized()
			var topspin_amount = -offset_normalizado.y
			var sidespin_amount = offset_normalizado.dot(right_axis)
			
			# LA CORRECCIÓN: Medimos la distancia desde el "centro de la mira" en 2D
			var distancia_del_centro = Vector2(sidespin_amount, topspin_amount).length()
			distancia_del_centro = clamp(distancia_del_centro, 0.0, 1.0) # Seguridad de 0 a 1
			
			# 4. POTENCIA Y EFICIENCIA
			var raw_force := _potencia_del_recorrido()
			
			# Ahora sí: Centro exacto = distancia 0.0 (Eficiencia 100%)
			# Borde extremo = distancia 1.0 (Eficiencia 65%)
			var power_efficiency = 1.0 - (distancia_del_centro * 0.80) 
			
			var hit_force = raw_force * power_efficiency
			hit_force = clamp(hit_force, 0.5, 20.0)
			# 3. IMPULSO LINEAL PURO
			ball.apply_central_impulse(hit_direction * hit_force)
			var peso_golpe = inverse_lerp(0.5, 20.0, hit_force)
			
			# Rango muy cerrado: de -8.0 dB (suave) a 0.0 dB (fuerte). Siempre se escuchará.
			sonido_taco.volume_db = lerp(-14.0, 0.0, peso_golpe)
			sonido_taco.play()
			# ============================================
			# MULTIPLICADORES INDEPENDIENTES
			# ============================================
			
			var spin_torque = Vector3.ZERO
			
			# Topspin / Backspin: 
			var topspin_multiplier = 0.7
			spin_torque += right_axis * (topspin_amount * topspin_multiplier)
			
			# Sidespin:
			var sidespin_multiplier = -0.2
			spin_torque += Vector3.UP * (sidespin_amount * sidespin_multiplier)
			
			# Aplicamos la fuerza del golpe al giro resultante
			# El giro usa la misma potencia del recorrido, antes de la eficiencia.
			spin_torque *= raw_force
			
			# Para que el sidespin sea l, subimos el max_torque temporalmente si es necesario
			var dynamic_max_torque = max_torque * 2.0
			if spin_torque.length() > dynamic_max_torque:
				spin_torque = spin_torque.normalized() * dynamic_max_torque
			
			ball.apply_torque_impulse(spin_torque)
			tiro_iniciado.emit()


						# 2. CAMBIO DE CMARA A LA MESA
			is_waiting_for_ball = true
			time_since_hit = 0.0
			if camera_mesa:
				camera_mesa.make_current() 
				is_waiting_for_ball = true 
				taco.global_position = Vector3(0,-1,0)
				time_since_hit = 0.0 #
func _potencia_del_recorrido() -> float:
	# Curva suave: deja más recorrido disponible para tiros bajos y medios.
	var proporcion := clampf(_recorrido_golpe / maxf(cue_max_pullback, 0.01), 0.0, 1.0)
	return lerpf(0.5, 20.0, pow(proporcion, cue_power_curve))


func _process(delta):
	if is_hitting_mode:
		_pausa_golpe += delta
		if _pausa_golpe >= cue_stop_seconds:
			_recorrido_golpe = 0.0
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
func _on_area_3d_body_entered(body):
	partida.registrar_caida(body)
func todas_las_bolas_detenidas() -> bool:
	# 1. Comprobamos la blanca primero (si se mueve, ya sabemos que no debemos cambiar la cámara)
	if not ball.freeze and not ball.sleeping and (ball.linear_velocity.length() >= 0.02 or ball.angular_velocity.length() >= 0.02):
		return false
		
	# 2. Obtenemos todas las bolas de color que sigan vivas en la escena
	var bolas_restantes = get_tree().get_nodes_in_group("bolas_color")
	
	# 3. Revisamos la velocidad de cada una de ellas
	for bola_color in bolas_restantes:
		if bola_color.is_queued_for_deletion() or bola_color.sleeping:
			continue
		if bola_color.linear_velocity.length() >= 0.02 or bola_color.angular_velocity.length() >= 0.02:
			return false # Encontramos al menos una moviéndose, cancelamos la comprobación
			
	# Si el código llega hasta aquí, significa que absolutamente nada se está moviendo
	return true

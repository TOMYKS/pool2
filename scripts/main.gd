extends Node3D

@export var camera: Camera3D
@export var camera_mesa: Camera3D
@export var marker: MeshInstance3D
@export var taco: AnimatableBody3D
@export var ball: RigidBody3D  # <--- Esta era la l­nea que faltaba

var time_since_hit: float = 0.0
var impact_point_global: Vector3
var is_aiming: bool = false
var is_hitting_mode: bool = false
@export var cue_speed_multiplier: float = 0.5 
var is_waiting_for_ball: bool = false
var max_forward_speed: float = 0.0

# --- CONFIGURACIN DE SPIN (Arcade) ---
## Radio de la bola (debe coincidir con el CollisionShape3D SphereShape3D)
@export var ball_radius: float = 0.14
## Multiplicador base para convertir el offset normalizado en torque
@export var spin_multiplier: float = 8.0
## Torque mÃ¡ximo permitido (clamp) para evitar spins absurdos
@export var max_torque: float = 3.0

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			shoot_raycast(event.position)
		else:
			# Al soltar el clic, el palo deja de seguir al rat
			is_hitting_mode = false
			
func shoot_raycast(mouse_pos: Vector2):
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
	print("--- INICIANDO TIRO ---")
	
	# 1. Verificamos dnde cree el juego que est la marca
	print("La marca estÃ¡ en: ", impact_point_global)
	
	# 2. Calculamos la posicn deseada
	var pos_camara = camera.global_position
	var direccion = Vector3(impact_point_global.x - pos_camara.x, 0, impact_point_global.z - pos_camara.z).normalized()
	
	var distancia_retiro = 1.0 
	var posicion_final = impact_point_global - (direccion * distancia_retiro)
	posicion_final.y = impact_point_global.y

	# 3. Forzamos el teletransporte alterando el Transform directamente
	taco.global_transform.origin = posicion_final
	taco.visible = true
	
	# 4. Apuntamos
	taco.look_at(impact_point_global, Vector3.UP)
	
	is_hitting_mode = true
	max_forward_speed = 0.0
func _input(event):
	# Si ya hicimos clic en la bola, el movimiento del ratn mueve el palo
	if is_hitting_mode and event is InputEventMouseMotion:
		var mouse_movement = event.relative.y
		var forward_vector = -taco.global_transform.basis.z
		
		# Track forward speed (negative mouse_movement means pushing forward usually, or positive depending on godot)
		# Let's just track the maximum absolute speed if it's pushing towards the ball
		var push_speed = abs(mouse_movement)
		if push_speed > max_forward_speed:
			max_forward_speed = push_speed
		
		# move_and_collide devuelve los datos de la colisn si choca con algo
		var motion = forward_vector * -mouse_movement * cue_speed_multiplier
		var collision = taco.move_and_collide(motion)
		
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
			var final_speed = max(max_forward_speed, abs(mouse_movement))
			
			# Ahora sí: Centro exacto = distancia 0.0 (Eficiencia 100%)
			# Borde extremo = distancia 1.0 (Eficiencia 65%)
			var power_efficiency = 1.0 - (distancia_del_centro * 0.80) 
			
			var hit_force = final_speed * cue_speed_multiplier * 2.5 * power_efficiency
			hit_force = clamp(hit_force, 0.5, 20.0)
			# 3. IMPULSO LINEAL PURO
			ball.apply_central_impulse(hit_direction * hit_force)
			
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
			# NOTA: Usamos la velocidad antes de aplicar la eficiencia para que el efecto sea pronunciado
			var raw_force = final_speed * cue_speed_multiplier * 2.5
			raw_force = clamp(raw_force, 0.5, 20.0)
			spin_torque *= raw_force
			
			# Para que el sidespin sea l, subimos el max_torque temporalmente si es necesario
			var dynamic_max_torque = max_torque * 2.0
			if spin_torque.length() > dynamic_max_torque:
				spin_torque = spin_torque.normalized() * dynamic_max_torque
			
			ball.apply_torque_impulse(spin_torque)
			
			print("--- GOLPE ARCADE ---")
			print("  Fuerza lineal: ", hit_force)
			print("  Eficiencia: ", power_efficiency)
			print("  Topspin: ", topspin_amount, " | Sidespin: ", sidespin_amount)


						# 2. CAMBIO DE CMARA A LA MESA
			if camera_mesa:
				camera_mesa.make_current() 
				is_waiting_for_ball = true 
				taco.global_position = Vector3(0,-1,0)
				time_since_hit = 0.0 #
func _process(delta):
	# 3. VIGILAR LA BOLA PARA VOLVER A LA CMARA DEL JUGADOR
	if is_waiting_for_ball:
		time_since_hit += delta
		
		# Esperamos 0.5 segundos antes de empezar a revisar si se detuvo
		if time_since_hit > 0.5:

			# Alternativa 2 (Recomendada): Comprobar que la velocidad sea casi nula
			if todas_las_bolas_detenidas():
				camera.make_current() # Volvemos a la cmara original
				is_waiting_for_ball = false
func _on_area_3d_body_entered(body):
	if body.is_in_group("bolas_color"):
		print("¡Una bola de color entro!")
		body.queue_free() # Elimina la bola de la mesa
		# Ais un punto o cambiaras de turno
		
	elif body.is_in_group("blanca"):
		print("¡Falta! Cayo la blanca.")
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.global_position = Vector3(2.821, 4.398, 0)
		# Cdigo para reposicionar la blanca en su punto de inicio (2.821,4.398,0)
func todas_las_bolas_detenidas() -> bool:
	# 1. Comprobamos la blanca primero (si se mueve, ya sabemos que no debemos cambiar la cámara)
	if ball.linear_velocity.length() >= 0.02 or ball.angular_velocity.length() >= 0.02:
		return false
		
	# 2. Obtenemos todas las bolas de color que sigan vivas en la escena
	var bolas_restantes = get_tree().get_nodes_in_group("bolas_color")
	
	# 3. Revisamos la velocidad de cada una de ellas
	for bola_color in bolas_restantes:
		if bola_color.linear_velocity.length() >= 0.02 or bola_color.angular_velocity.length() >= 0.02:
			return false # Encontramos al menos una moviéndose, cancelamos la comprobación
			
	# Si el código llega hasta aquí, significa que absolutamente nada se está moviendo
	return true

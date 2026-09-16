extends Node3D

@export var camera: Camera3D
@export var camera_mesa: Camera3D
@export var marker: MeshInstance3D
@export var taco: AnimatableBody3D
@export var ball: RigidBody3D  # <--- Esta era la línea que faltaba

var time_since_hit: float = 0.0
var impact_point_global: Vector3
var is_aiming: bool = false
var is_hitting_mode: bool = false
@export var cue_speed_multiplier: float = 0.5 
var is_waiting_for_ball: bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			shoot_raycast(event.position)
		else:
			# Al soltar el clic, el palo deja de seguir al ratón
			is_hitting_mode = false
			
func shoot_raycast(mouse_pos: Vector2):
	var space_state = get_world_3d().direct_space_state
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space_state.intersect_ray(query)
	
	# Si el rayo chocó con algo, y ese algo es nuestra bola
	if result and result.collider == ball:
		impact_point_global = result.position
		marker.global_position = impact_point_global
		marker.visible = true
		
		# Preparamos el palo
		setup_cue_stick()

func setup_cue_stick():
	print("--- INICIANDO TIRO ---")
	
	# 1. Verificamos dónde cree el juego que está la marca
	print("La marca está en: ", impact_point_global)
	
	# 2. Calculamos la posición deseada
	var pos_camara = camera.global_position
	var direccion = Vector3(impact_point_global.x - pos_camara.x, 0, impact_point_global.z - pos_camara.z).normalized()
	
	var distancia_retiro = 1.0 
	var posicion_final = impact_point_global - (direccion * distancia_retiro)
	posicion_final.y = impact_point_global.y
	
	print("Queremos mover el palo a: ", posicion_final)
	
	# 3. Forzamos el teletransporte alterando el Transform directamente
	taco.global_transform.origin = posicion_final
	taco.visible = true
	
	# 4. Apuntamos
	taco.look_at(impact_point_global, Vector3.UP)
	
	print("El palo quedó realmente en: ", taco.global_position)
	is_hitting_mode = true
func _input(event):
	# Si ya hicimos clic en la bola, el movimiento del ratón mueve el palo
	if is_hitting_mode and event is InputEventMouseMotion:
		var mouse_movement = event.relative.y
		var forward_vector = -taco.global_transform.basis.z
		
		# move_and_collide devuelve los datos de la colisión si choca con algo
		var motion = forward_vector * -mouse_movement * cue_speed_multiplier
		var collision = taco.move_and_collide(motion)
		
		# Si chocamos con la bola, terminamos el modo de golpe
		if collision and collision.get_collider() == ball:
			is_hitting_mode = false
			marker.visible = false
			taco.visible = false # Ocultamos el palo
			
			# 1. GOLPE CON EFECTO: Usar apply_impulse con un OFFSET
			var hit_direction = -taco.global_transform.basis.z.normalized()
			var hit_force = abs(mouse_movement) * cue_speed_multiplier * 2.0 # Ajusta esta fuerza
			
			# Calculamos la distancia desde el centro de la bola al punto rojo
			var offset_impacto = impact_point_global - ball.global_position
			
			# apply_impulse aplica fuerza y rotación automática al no golpear en el centro
			ball.apply_impulse(hit_direction * hit_force, offset_impacto)
			
			# 2. CAMBIO DE CÁMARA A LA MESA
			if camera_mesa:
				camera_mesa.make_current() 
				is_waiting_for_ball = true 
				time_since_hit = 0.0 #
func _process(delta):
	# 3. VIGILAR LA BOLA PARA VOLVER A LA CÁMARA DEL JUGADOR
	if is_waiting_for_ball:
		time_since_hit += delta
		
		# Esperamos 0.5 segundos antes de empezar a revisar si se detuvo
		if time_since_hit > 0.5:

			# Alternativa 2 (Recomendada): Comprobar que la velocidad sea casi nula
			if ball.linear_velocity.length() < 0.05 and ball.angular_velocity.length() < 0.05:
				camera.make_current() # Volvemos a la cámara original
				is_waiting_for_ball = false
func _on_area_3d_body_entered(body):
	if body.is_in_group("bolas_color"):
		print("¡Una bola de color entró!")
		body.queue_free() # Elimina la bola de la mesa
		# Aquí sumarías un punto o cambiarías de turno
		
	elif body.is_in_group("blanca"):
		print("¡Falta! Cayó la blanca.")
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.global_position = Vector3(2.821, 4.398, 0)
		# Código para reposicionar la blanca en su punto de inicio (2.821,4.398,0)

extends Node3D

@export var camera: Camera3D
@export var marker: MeshInstance3D
@export var taco: AnimatableBody3D
@export var ball: RigidBody3D  # <--- Esta era la línea que faltaba

var impact_point_global: Vector3
var is_aiming: bool = false
var is_hitting_mode: bool = false
var cue_speed_multiplier: float = 0.05 

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
			
			# 1. Obtenemos la dirección hacia donde apunta el taco (eje -Z)
			var hit_direction = -taco.global_transform.basis.z.normalized()
			
			# 2. Calculamos la fuerza basándonos en el movimiento del ratón
			# Usamos abs() para garantizar un valor positivo y multiplicamos por un factor de fuerza
			var force_multiplier = 0.2 # Ajusta este valor a tu gusto
			var hit_force = abs(mouse_movement) * force_multiplier 
			
			# 3. Aplicamos el impulso a la bola
			ball.apply_central_impulse(hit_direction * hit_force)
			
			# Opcional: Ocultar el taco tras el golpe
			taco.visible = false

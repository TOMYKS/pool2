extends "res://scripts/grandes.gd"

# Altura del paño de Sala; el radio nuevo determina el centro de la bola.
const ALTURA_PANO := 4.1761234
const TOLERANCIA_ALTURA := 0.003
const VELOCIDAD_REPOSO := 0.08
const GIRO_REPOSO := 0.3
const TIEMPO_REPOSO := 0.4


func activar_bolas_grandes() -> void:
	if powerup_grandes_activo:
		return
	super.activar_bolas_grandes()
	var espacio: Node3D = sala if sala != null else get_parent() as Node3D
	for datos in _bolas_originales:
		var bola: RigidBody3D = datos["bola"]
		datos["bloqueo_y_original"] = bola.axis_lock_linear_y
		var colision: CollisionShape3D = datos["colision"]
		var radio := (colision.shape as SphereShape3D).radius
		var techo := espacio.to_global(Vector3(0, ALTURA_PANO + radio, 0)).y
		# El techo no debe quedar dentro del paño por una pequeña penetración.
		# Corregir solo por arriba sigue permitiendo caer hacia una tronera.
		datos["altura_maxima"] = techo
		datos["tiempo_lento"] = 0.0
		bola.axis_lock_linear_y = false
		_limitar_subida(bola, datos["altura_maxima"])
		bola.sleeping = false


func _physics_process(delta: float) -> void:
	if not powerup_grandes_activo:
		return
	for datos in _bolas_originales:
		var bola = datos["bola"]
		if is_instance_valid(bola) and not bola.is_queued_for_deletion() and not bola.sleeping:
			_limitar_subida(bola, datos["altura_maxima"])
			_actualizar_reposo(bola, datos, delta)


func _limitar_subida(bola: RigidBody3D, altura_maxima: float) -> void:
	var velocidad := bola.linear_velocity
	if velocidad.y > 0.01:
		velocidad.y = 0.0
		bola.linear_velocity = velocidad
	# Un choque puede desplazarla durante el paso físico: tampoco dejamos
	# que ese desplazamiento la levante sobre el plano del paño.
	if bola.global_position.y > altura_maxima + TOLERANCIA_ALTURA:
		var posicion := bola.global_position
		posicion.y = altura_maxima
		bola.global_position = posicion


func _actualizar_reposo(bola: RigidBody3D, datos: Dictionary, delta: float) -> void:
	if bola.linear_velocity.length() >= VELOCIDAD_REPOSO or bola.angular_velocity.length() >= GIRO_REPOSO:
		datos["tiempo_lento"] = 0.0
		return
	var radio := (datos["colision"].shape as SphereShape3D).radius
	var origen := bola.global_position
	var consulta := PhysicsRayQueryParameters3D.create(
		origen, origen + Vector3.DOWN * (radio + 0.03),
		bola.collision_mask, [bola.get_rid()]
	)
	var apoyo := bola.get_world_3d().direct_space_state.intersect_ray(consulta)
	# No frenar una caída ni una bola suspendida sobre otra.
	if apoyo.is_empty() or not (apoyo.collider is StaticBody3D) or apoyo.normal.y < 0.9:
		datos["tiempo_lento"] = 0.0
		return
	datos["tiempo_lento"] += delta
	if datos["tiempo_lento"] >= TIEMPO_REPOSO:
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO
		bola.sleeping = true


func desactivar_bolas_grandes() -> void:
	if not powerup_grandes_activo:
		return
	for datos in _bolas_originales:
		var bola = datos["bola"]
		if is_instance_valid(bola) and not bola.is_queued_for_deletion():
			bola.axis_lock_linear_y = datos["bloqueo_y_original"]
	super.desactivar_bolas_grandes()


func _exit_tree() -> void:
	desactivar_bolas_grandes()

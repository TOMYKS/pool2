extends RefCounted

# Evitar que los contactos entre bolas prolonguen un movimiento imperceptible.
const VELOCIDAD_MINIMA := 0.06
const VELOCIDAD_GIRO_MINIMA := 0.10
const TIEMPO_PARA_REPOSO := 0.35
# Un rebote mínimo o una esfera encajada pueden conservar velocidad de solver
# sin movimiento apreciable. Exigir posición estable y apoyo antes de dormirla.
const OSCILACION_MAXIMA := 0.01
const TIEMPO_OSCILACION := 0.6
var _tiempo_lento := 0.0
var _tiempo_oscilacion := 0.0
var _posicion_minima := Vector3.ZERO
var _posicion_maxima := Vector3.ZERO


func actualizar(bola: RigidBody3D, delta: float) -> void:
	if bola.freeze or bola.sleeping:
		_tiempo_lento = 0.0
		_tiempo_oscilacion = 0.0
		return
	_tiempo_lento = _tiempo_lento + delta if puede_detenerse(bola) else 0.0
	if _tiempo_lento >= TIEMPO_PARA_REPOSO or _oscilacion_estable(bola, delta):
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO
		bola.sleeping = true
		_tiempo_lento = 0.0
		_tiempo_oscilacion = 0.0


func _oscilacion_estable(bola: RigidBody3D, delta: float) -> bool:
	var colision := bola.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if colision == null or not colision.shape is SphereShape3D:
		_tiempo_oscilacion = 0.0
		return false
	var radio: float = colision.shape.radius * absf(colision.global_basis.get_scale().y)
	# Conservar el avance y el efecto horizontal que aún pueden mover la bola.
	var avance := Vector2(bola.linear_velocity.x, bola.linear_velocity.z).length()
	var giro_superficie := Vector2(bola.angular_velocity.x, bola.angular_velocity.z).length() * radio
	if avance >= VELOCIDAD_MINIMA or giro_superficie >= VELOCIDAD_GIRO_MINIMA or not _tiene_apoyo_estatico(bola, colision.global_position, radio):
		_tiempo_oscilacion = 0.0
		return false
	var posicion := colision.global_position
	if _tiempo_oscilacion == 0.0:
		_posicion_minima = posicion
		_posicion_maxima = posicion
	_posicion_minima = _posicion_minima.min(posicion)
	_posicion_maxima = _posicion_maxima.max(posicion)
	if (_posicion_maxima - _posicion_minima).length() > OSCILACION_MAXIMA:
		_tiempo_oscilacion = 0.0
		return false
	_tiempo_oscilacion += delta
	return _tiempo_oscilacion >= TIEMPO_OSCILACION


static func _tiene_apoyo_estatico(bola: RigidBody3D, origen: Vector3, radio: float) -> bool:
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + Vector3.DOWN * (radio + 0.02), bola.collision_mask, [bola.get_rid()])
	var apoyo := bola.get_world_3d().direct_space_state.intersect_ray(consulta)
	if not apoyo.is_empty() and apoyo.collider is StaticBody3D and apoyo.normal.y >= 0.9:
		return true
	# Una bola grande puede apoyarse en ambos labios de una tronera: el rayo
	# central pasa por el hueco, aunque los contactos reales sí la sostienen.
	if bola.contact_monitor:
		for cuerpo in bola.get_colliding_bodies():
			if cuerpo is StaticBody3D:
				return true
	return false


static func puede_detenerse(bola: RigidBody3D) -> bool:
	if bola.linear_velocity.length() >= VELOCIDAD_MINIMA:
		return false
	var colision := bola.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if colision == null or not colision.shape is SphereShape3D:
		return false
	var radio: float = colision.shape.radius * absf(colision.global_basis.get_scale().y)
	# Medir la velocidad en la superficie también sirve con bolas grandes.
	# El giro vertical no desplaza una esfera: no debe mantener abierto el turno.
	# El giro horizontal sí puede producir retroceso o avance y se conserva.
	if Vector2(bola.angular_velocity.x, bola.angular_velocity.z).length() * radio >= VELOCIDAD_GIRO_MINIMA:
		return false
	var origen := colision.global_position
	var consulta := PhysicsRayQueryParameters3D.create(
		origen, origen + Vector3.DOWN * (radio + 0.02),
		bola.collision_mask, [bola.get_rid()]
	)
	var apoyo := bola.get_world_3d().direct_space_state.intersect_ray(consulta)
	# No detener una caída en una tronera ni una bola sostenida por otra bola.
	return not apoyo.is_empty() and apoyo.collider is StaticBody3D and apoyo.normal.y >= 0.9

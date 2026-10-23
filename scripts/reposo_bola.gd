extends RefCounted

# Evitar que los contactos entre bolas prolonguen un movimiento imperceptible.
const VELOCIDAD_MINIMA := 0.06
const VELOCIDAD_GIRO_MINIMA := 0.10
const TIEMPO_PARA_REPOSO := 0.35
var _tiempo_lento := 0.0


func actualizar(bola: RigidBody3D, delta: float) -> void:
	if bola.freeze or bola.sleeping or not puede_detenerse(bola):
		_tiempo_lento = 0.0
		return
	_tiempo_lento += delta
	if _tiempo_lento >= TIEMPO_PARA_REPOSO:
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO
		bola.sleeping = true
		_tiempo_lento = 0.0


static func puede_detenerse(bola: RigidBody3D) -> bool:
	if bola.linear_velocity.length() >= VELOCIDAD_MINIMA:
		return false
	var colision := bola.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if colision == null or not colision.shape is SphereShape3D:
		return false
	var radio: float = colision.shape.radius * absf(colision.global_basis.get_scale().y)
	# Medir la velocidad en la superficie también sirve con bolas grandes.
	if bola.angular_velocity.length() * radio >= VELOCIDAD_GIRO_MINIMA:
		return false
	var origen := colision.global_position
	var consulta := PhysicsRayQueryParameters3D.create(
		origen, origen + Vector3.DOWN * (radio + 0.02),
		bola.collision_mask, [bola.get_rid()]
	)
	var apoyo := bola.get_world_3d().direct_space_state.intersect_ray(consulta)
	# No detener una caída en una tronera ni una bola sostenida por otra bola.
	return not apoyo.is_empty() and apoyo.collider is StaticBody3D and apoyo.normal.y >= 0.9

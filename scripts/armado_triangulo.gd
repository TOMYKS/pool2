extends RefCounted

# Partir de la composición manual y variar solo al cargar la mesa.
# El generador recibido permite reproducir y verificar cada armado.
static func preparar(bolas: Array, variacion: float, angulo_grados: float, azar: RandomNumberGenerator, separacion: float = 1.0) -> void:
	if bolas.is_empty() or (variacion <= 0.0 and angulo_grados <= 0.0 and is_equal_approx(separacion, 1.0)):
		return
	var punta: Vector3 = bolas[0].position
	for bola: RigidBody3D in bolas:
		if bola.position.x > punta.x:
			punta = bola.position
	var angulo := deg_to_rad(azar.randf_range(-angulo_grados, angulo_grados))
	var desplazamiento := Vector3(0, 0, azar.randf_range(-variacion, variacion))
	var posiciones: Array[Vector3] = []
	var radios: Array[float] = []
	for bola: RigidBody3D in bolas:
		var offset := bola.position - punta
		offset.x *= separacion
		offset.z *= separacion
		posiciones.append(punta + offset.rotated(Vector3.UP, angulo) + desplazamiento)
		radios.append(bola.get_node("CollisionShape3D").shape.radius)
	for i in range(bolas.size()):
		var origen := posiciones[i]
		for intento in range(32):
			var candidato := origen + Vector3(azar.randf_range(-variacion, variacion), 0, azar.randf_range(-variacion, variacion))
			var libre := true
			for j in range(bolas.size()):
				if j != i and candidato.distance_to(posiciones[j]) < radios[i] + radios[j] + 0.00005:
					libre = false
					break
			if libre:
				posiciones[i] = candidato
				break
	for i in range(bolas.size()):
		bolas[i].position = posiciones[i]

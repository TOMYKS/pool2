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

# Abrir el triángulo sin concentrar casi todo el impacto en una sola fila.
static func repartir_impacto(bolas: Array) -> void:
	var masa_total := 0.0
	var centro := Vector3.ZERO
	var momento := Vector3.ZERO
	var energia := 0.0
	for bola: RigidBody3D in bolas:
		if not is_instance_valid(bola) or bola.freeze or bola.is_queued_for_deletion():
			return
		masa_total += bola.mass
		centro += bola.global_position * bola.mass
		var velocidad := bola.linear_velocity
		velocidad.y = 0.0
		momento += velocidad * bola.mass
		energia += 0.5 * bola.mass * velocidad.length_squared()
	if masa_total <= 0.0:
		return
	centro /= masa_total
	var avance := momento / masa_total
	var dispersion := 0.0
	for bola: RigidBody3D in bolas:
		var radial := bola.global_position - centro
		radial.y = 0.0
		dispersion += bola.mass * radial.length_squared()
	# Una esfera maciza rodando necesita 1.4 veces su energía de traslación.
	var energia_radial := energia * 0.85 / 1.4 - 0.5 * masa_total * avance.length_squared()
	if dispersion <= 0.0 or energia_radial <= 0.0:
		return
	var escala := sqrt(2.0 * energia_radial / dispersion)
	for bola: RigidBody3D in bolas:
		var radial := bola.global_position - centro
		radial.y = 0.0
		var salida := avance + radial * escala
		var radio := preload("res://scripts/fisica_bola.gd").radio_de(bola)
		bola.sleeping = false
		bola.linear_velocity = salida
		bola.angular_velocity = Vector3.UP.cross(salida) / radio

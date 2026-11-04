extends SceneTree
var errores := 0
func _initialize() -> void:
	probar.call_deferred()
func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		errores += 1
		push_error(mensaje)
func probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	var bolas: Array = sala.get_node("Bolas").get_children()
	var originales: Array[Vector3] = []
	for bola: RigidBody3D in bolas:
		originales.append(bola.position)
	var primero: Array[Vector3] = []
	var distinto := false
	var max_cambio := 0.0
	var punta := originales[0]
	for posicion in originales:
		if posicion.x > punta.x:
			punta = posicion
	var alcance := 0.0
	for posicion in originales:
		alcance = maxf(alcance, posicion.distance_to(punta))
	var limite_cambio: float = alcance * absf(sala.separacion_triangulo - 1.0) + alcance * sala.separacion_triangulo * 2.0 * sin(deg_to_rad(sala.angulo_triangulo) * 0.5) + sala.variacion_triangulo * 3.0
	for semilla in range(500):
		for i in range(bolas.size()):
			bolas[i].position = originales[i]
		var azar := RandomNumberGenerator.new()
		azar.seed = semilla
		preload("res://scripts/armado_triangulo.gd").preparar(bolas, sala.variacion_triangulo, sala.angulo_triangulo, azar, sala.separacion_triangulo)
		for i in range(bolas.size()):
			max_cambio = maxf(max_cambio, bolas[i].position.distance_to(originales[i]))
			comprobar(is_equal_approx(bolas[i].position.y, originales[i].y), "Conservar la altura de todas las bolas")
			comprobar(bolas[i].linear_velocity.is_zero_approx() and bolas[i].angular_velocity.is_zero_approx(), "El armado no debe añadir impulsos ni giro")
			if semilla == 0:
				primero.append(bolas[i].position)
			else:
				distinto = distinto or not bolas[i].position.is_equal_approx(primero[i])
			for j in range(i):
				var radio_i: float = bolas[i].get_node("CollisionShape3D").shape.radius
				var radio_j: float = bolas[j].get_node("CollisionShape3D").shape.radius
				comprobar(bolas[i].position.distance_to(bolas[j].position) >= radio_i + radio_j, "Ninguna pareja puede comenzar solapada")
	comprobar(distinto and max_cambio <= limite_cambio + 0.00001, "Respetar los límites de separación y variación del Inspector")
	for i in range(bolas.size()):
		bolas[i].position = originales[i]
	var sin_variacion := RandomNumberGenerator.new()
	preload("res://scripts/armado_triangulo.gd").preparar(bolas, 0.0, 0.0, sin_variacion)
	for i in range(bolas.size()):
		comprobar(bolas[i].position == originales[i], "Con los dos ajustes en cero debe mantenerse exactamente el armado manual")
	sala.free()
	# Integración real: deben permanecer quietas hasta el golpe.
	sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	await process_frame
	await process_frame
	sala.get_node("Partida").comenzar_partida(false)
	paused = false
	var posiciones: Array[Vector3] = []
	for bola in sala.get_node("Bolas").get_children():
		posiciones.append(bola.position)
	for i in range(Engine.physics_ticks_per_second):
		await physics_frame
	for i in range(15):
		var bola: RigidBody3D = sala.get_node("Bolas").get_child(i)
		var horizontal := Vector2(bola.position.x - posiciones[i].x, bola.position.z - posiciones[i].z)
		comprobar(horizontal.length() < 0.002 and bola.linear_velocity.length() < 0.06, "Las bolas no deben separarse por sí solas antes del saque")
	sala.queue_free()
	await process_frame
	print("TRIANGULO: ", errores, " errores en 500 armados, cambio máximo=", max_cambio)
	quit(1 if errores else 0)

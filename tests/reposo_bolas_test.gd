extends SceneTree

var errores := 0
const ALTURA_PANO := 4.1761234


func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	_probar.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func _probar() -> void:
	var mesa = load("res://scenes/mesa.tscn").instantiate()
	root.add_child(mesa)
	var sala = load("res://scenes/sala.tscn").instantiate()
	var modelos: Array[RigidBody3D] = [sala.get_node("Ball0"), sala.get_node("Bolas/Ball1"), sala.get_node("Bolas/Ball2")]
	for bola in modelos:
		bola.get_parent().remove_child(bola)
	sala.free()
	# Bolas casi en contacto: el movimiento residual debe desaparecer pronto.
	for cantidad in [2, 3]:
		var bolas: Array[RigidBody3D] = []
		for i in range(cantidad):
			var bola := modelos[i].duplicate() as RigidBody3D
			var radio: float = bola.get_node("CollisionShape3D").shape.radius
			bola.position = Vector3(i * 0.281, ALTURA_PANO + radio, 0)
			bola.linear_velocity = Vector3(0.04 if i == 0 else -0.04, 0, 0)
			root.add_child(bola)
			bolas.append(bola)
		for paso in range(90):
			await physics_frame
		for bola in bolas:
			comprobar(bola.sleeping and bola.linear_velocity.is_zero_approx() and bola.angular_velocity.is_zero_approx(), "Detener movimiento residual con %d bolas en contacto" % cantidad)
		# Una bola dormida debe despertar al recibir el golpe de la blanca.
		bolas[0].apply_central_impulse(Vector3(0.8, 0, 0))
		var desperto_color := false
		for paso in range(20):
			await physics_frame
			desperto_color = desperto_color or (not bolas[1].sleeping and bolas[1].linear_velocity.length() > 0.1)
		comprobar(desperto_color, "Un nuevo choque despierta las bolas detenidas")
		for bola in bolas:
			bola.queue_free()
		await process_frame

	for modelo in modelos:
		var bola := modelo.duplicate() as RigidBody3D
		var radio: float = bola.get_node("CollisionShape3D").shape.radius
		bola.position = Vector3(0, ALTURA_PANO + radio, 0)
		bola.linear_velocity = Vector3(0.4, 0, 0)
		bola.angular_velocity = Vector3(0, 0, -0.4 / radio)
		root.add_child(bola)
		for paso in range(30):
			await physics_frame
		comprobar(not bola.sleeping and bola.position.x > 0.1, "Conservar un tiro suave que todavía tiene velocidad")
		bola.queue_free()
		await process_frame
		# Empieza casi quieta y sin apoyo en la boca de la tronera central.
		bola = modelo.duplicate() as RigidBody3D
		bola.position = Vector3(0, ALTURA_PANO + radio, 2.65)
		root.add_child(bola)
		for paso in range(45):
			await physics_frame
		comprobar(bola.position.y < 3.5, "La bola quieta sobre una tronera debe seguir cayendo")
		bola.queue_free()
		await process_frame
	for modelo in modelos:
		modelo.free()
	mesa.queue_free()
	await process_frame
	print("REPOSO BOLAS TEST: ", errores, " errores")
	quit(1 if errores else 0)

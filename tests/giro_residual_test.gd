extends SceneTree
var errores := 0
func _initialize() -> void:
	probar.call_deferred()
func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		errores += 1
		push_error(mensaje)
func probar() -> void:
	var mesa = load("res://scenes/mesa.tscn").instantiate()
	root.add_child(mesa)
	var sala = load("res://scenes/sala.tscn").instantiate()
	var modelos: Array[RigidBody3D] = [sala.get_node("Ball0"), sala.get_node("Bolas/Ball1")]
	for bola in modelos:
		bola.get_parent().remove_child(bola)
	sala.free()
	for modelo in modelos:
		for giro_y in [-80.0, 80.0]:
			var bola := modelo.duplicate() as RigidBody3D
			bola.position = Vector3(0, 4.1761234 + bola.get_node("CollisionShape3D").shape.radius, 0)
			bola.angular_velocity = Vector3(0, giro_y, 0)
			root.add_child(bola)
			for i in range(int(Engine.physics_ticks_per_second * 1.5)):
				await physics_frame
			comprobar(bola.sleeping and bola.angular_velocity.is_zero_approx(), "Una bola sin avance no debe seguir girando verticalmente")
			comprobar(Vector2(bola.position.x, bola.position.z).length() < 0.03, "Frenar el giro vertical no debe desplazar la bola")
			bola.free()
			await process_frame
	# Conservar el efecto mientras la blanca avanza, en ambos sentidos.
	for fuerza in [0.5, 6.0, 20.0]:
		for efecto in [-1.0, 1.0]:
			var bola := modelos[0].duplicate() as RigidBody3D
			bola.position = Vector3(0, 4.3161234, 0)
			root.add_child(bola)
			await process_frame
			bola.apply_central_impulse(Vector3.RIGHT * fuerza)
			bola.angular_velocity = Vector3(0, efecto * 12, -fuerza / (bola.mass * 0.14))
			for i in range(int(Engine.physics_ticks_per_second * 0.15)):
				await physics_frame
			comprobar(bola.position.x > 0.025 and bola.linear_velocity.x > 0.1, "Los golpes bajos, medios y altos deben conservar el avance")
			comprobar(bola.angular_velocity.y * efecto > 0.5, "El efecto lateral debe seguir activo mientras hay avance")
			bola.free()
			await process_frame
	# Topspin/backspin no deben desaparecer por el nuevo freno vertical.
	for fuerza in [0.5, 6.0, 20.0]:
		for efecto in [-1.0, 1.0]:
			var bola := modelos[0].duplicate() as RigidBody3D
			bola.position = Vector3(0, 4.3161234, 0)
			root.add_child(bola)
			await process_frame
			bola.apply_central_impulse(Vector3.RIGHT * fuerza)
			bola.angular_velocity = Vector3(0, 0, efecto * fuerza / (bola.mass * 0.14))
			for i in range(int(Engine.physics_ticks_per_second * 0.04)):
				await physics_frame
			comprobar(bola.angular_velocity.z * efecto > 0.5, "Conservar el giro de avance y retroceso en las tres fuerzas")
			bola.free()
			await process_frame
	for modelo in modelos:
		modelo.free()
	mesa.free()
	print("GIRO RESIDUAL: ", errores, " errores en 16 casos")
	quit(1 if errores else 0)

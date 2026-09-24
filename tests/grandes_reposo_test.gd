extends SceneTree

var errores := 0

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)

func _probar() -> void:
	var sala := Node3D.new()
	root.add_child(sala)
	var suelo := StaticBody3D.new()
	var piso := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(12, 1, 8)
	piso.shape = caja
	suelo.add_child(piso)
	sala.add_child(suelo)
	suelo.position.y = 3.6761234
	var bola := RigidBody3D.new()
	var colision := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.14
	colision.shape = esfera
	bola.add_child(colision)
	bola.mass = 0.8
	bola.angular_damp = 2
	bola.physics_material_override = PhysicsMaterial.new()
	bola.physics_material_override.friction = 0.4
	bola.physics_material_override.bounce = 0.9
	sala.add_child(bola)
	bola.add_to_group("bolas_color")
	var poder = load("res://scenes/grandes.tscn").instantiate()
	sala.add_child(poder)
	for factor in [2.0, 3.0]:
		# Pequeña penetración representativa de una bola apoyada.
		bola.position = Vector3(0, 4.3161234 - 0.003, 0)
		bola.sleeping = false
		poder.multiplicador_tamano = factor
		poder.activar_bolas_grandes()
		bola.linear_velocity = Vector3(0.05, 0, 0)
		bola.angular_velocity = Vector3(0, 0, -0.05 / colision.shape.radius)
		for paso in range(180):
			await physics_frame
		print("x", factor, " velocidad=", bola.linear_velocity.length(), " giro=", bola.angular_velocity.length(), " dormida=", bola.sleeping)
		comprobar(bola.sleeping, "Una bola grande casi detenida debe entrar en reposo")
		bola.apply_central_impulse(Vector3(1, 0, 0))
		for paso in range(4):
			await physics_frame
		comprobar(not bola.sleeping and bola.linear_velocity.x > 0.2, "Debe volver a moverse con un golpe")
		# Sin apoyo, como al entrar en una tronera, nunca debe dormirse en el aire.
		bola.position = Vector3(20, 4.1761234 + colision.shape.radius, 0)
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO
		bola.sleeping = false
		for paso in range(40):
			await physics_frame
		comprobar(bola.position.y < 3.5, "Debe seguir cayendo sin apoyo")
		poder.desactivar_bolas_grandes()
	print("GRANDES REPOSO TEST: ", errores, " errores")
	quit(1 if errores else 0)

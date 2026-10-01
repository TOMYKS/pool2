extends SceneTree

func _initialize() -> void:
	create_timer(15).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	await process_frame
	for paso in range(30):
		await physics_frame
	var blanca: RigidBody3D = sala.ball
	var objetivo: RigidBody3D = sala.get_node("Bolas/Ball1")
	var partida = sala.get_node("Partida")
	var direccion := objetivo.global_position - blanca.global_position
	direccion.y = 0
	blanca.apply_central_impulse(direccion.normalized() * 18.0)
	sala.tiro_iniciado.emit()
	sala.is_waiting_for_ball = true
	sala.time_since_hit = 0.0
	var hubo_sonido := false
	var hubo_contacto := false
	for paso in range(150):
		await physics_frame
		hubo_contacto = hubo_contacto or partida.reglas.primer_contacto > 0
		for bola in get_nodes_in_group("bolas_color"):
			if bola.get_node("SonidoChoqueBlanca").playing:
				hubo_sonido = true
	var correcto := hubo_contacto and hubo_sonido
	if not correcto:
		push_error("El saque debe registrar contacto y reproducir el sonido desde la bola de color.")
	print("SAQUE TEST: contacto=", hubo_contacto, ", sonido=", hubo_sonido)
	sala.get_node("MusicaFondo").stop()
	quit(0 if correcto else 1)

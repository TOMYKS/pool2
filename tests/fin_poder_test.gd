extends SceneTree

var fallos := 0

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func _probar() -> void:
	for turno in [1, 2]:
		var sala = load("res://scenes/sala.tscn").instantiate()
		root.add_child(sala)
		await process_frame
		await physics_frame
		sala.set_process(false)
		var partida = sala.get_node("Partida")
		var poderes = sala.get_node("Powerups")
		var negra = sala.get_node("Bolas/Ball8")
		for bola in get_nodes_in_group("bolas_color"):
			if bola != negra:
				bola.queue_free()
		await process_frame
		partida.reglas.saque = false
		partida.reglas.turno = turno
		partida.reglas.grupos = [1, 2]
		partida.reglas.restantes.assign([8])
		sala.ball.freeze = true
		sala.ball.linear_velocity = Vector3.ZERO
		sala.ball.angular_velocity = Vector3.ZERO
		poderes.habilitado = true
		poderes._guardar_originales()
		var grandes = poderes._controladores[poderes.TipoPoder.GRANDES]
		grandes.multiplicador_tamano = 3.0
		grandes.activar_bolas_grandes()
		poderes.poder_actual = poderes.TipoPoder.GRANDES
		poderes.tiros_restantes = 1
		poderes._tiro_recogida = 0
		sala.tiro_iniciado.emit()
		partida.reglas.contacto(8)
		negra.global_position = Vector3(0, 4.1761234 + 0.14083566 * 3, 2.65)
		negra.linear_velocity = Vector3.ZERO
		negra.angular_velocity = Vector3.ZERO
		negra.sleeping = true
		sala.is_waiting_for_ball = true
		sala.time_since_hit = 1.0
		sala._process(0.31)
		comprobar(poderes.poder_actual == -1, "El poder vence antes de resolver las reglas")
		comprobar(partida.reglas.en_tiro and partida.reglas.turno == turno, "Mantener el tiro y su jugador al encoger")
		comprobar(sala.is_waiting_for_ball, "No habilitar un nuevo tiro durante la caída")
		comprobar(not poderes.preparar_fin_tiro(), "Vencimiento se procesa una sola vez")
		sala.set_process(true)
		# La bola vuelve a su radio normal y cae de verdad por la tronera.
		for paso in range(240):
			await physics_frame
			if partida.terminada:
				break
		comprobar(partida.terminada, "La caída tardía de la negra debe terminar la partida")
		comprobar(partida.reglas.ganador == turno, "La negra corresponde al jugador del tiro que vence")
		comprobar(not is_instance_valid(negra), "La negra se retiró físicamente")
		comprobar(not is_instance_valid(poderes.activador), "No generar un activador tras el final")
		sala.get_node("MusicaFondo").stop()
		sala.queue_free()
		await process_frame
	print("FIN PODER TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)

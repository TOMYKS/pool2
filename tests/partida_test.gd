extends SceneTree

var fallos := 0
var sala
var partida

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)

func _probar() -> void:
	sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	await process_frame
	await physics_frame
	partida = sala.get_node("Partida")
	comprobar(sala.get_node("Bolas/Ball10").get_meta("numero") == 11, "Identidad según el modelo visible")
	comprobar(sala.get_node("Bolas/Ball11").get_meta("numero") == 10, "Modelo 10 correctamente identificado")
	comprobar(partida.puede_apuntar(), "Jugador 1 listo para el saque")
	sala.tiro_iniciado.emit()
	partida.reglas.contacto(1)
	partida.reglas.banda(1)
	partida.finalizar_tiro()
	comprobar(partida.bola_en_mano and partida.reglas.turno == 2, "Saque inválido da bola en mano al rival")
	comprobar(sala.camera_mesa.is_current(), "Bola en mano mantiene cámara general")
	comprobar(sala.ball.freeze and not sala.ball.visible, "Blanca retirada hasta colocarla")
	comprobar(not partida.puede_apuntar(), "No se puede disparar mientras se coloca")
	var centro := Vector3(0, 4.3261234, 0)
	comprobar(partida.posicion_valida(centro), "Centro libre aceptado")
	comprobar(not partida.posicion_valida(Vector3(6, centro.y, 0)), "Rechaza fuera de la mesa")
	comprobar(not partida.posicion_valida(Vector3(4.6, centro.y, 2.1)), "Rechaza tronera")
	var ocupada: Vector3 = sala.get_node("Bolas/Ball1").global_position
	ocupada.y = centro.y
	comprobar(not partida.posicion_valida(ocupada), "Rechaza superponer otra bola")
	var pared = sala.get_node("Powerups")._controladores[3]
	pared.activar_pared()
	await physics_frame
	var punto_pared: Vector3 = pared.pared.global_position
	punto_pared.y = centro.y
	comprobar(not partida.posicion_valida(punto_pared), "Rechaza colocar dentro de la pared")
	pared.desactivar_pared()
	await physics_frame
	var pantalla: Vector2 = sala.camera_mesa.unproject_position(centro)
	partida.solicitar_colocacion(pantalla)
	await physics_frame
	await physics_frame
	comprobar(not partida.bola_en_mano and sala.camera.is_current(), "Clic coloca blanca y vuelve a apuntado")
	comprobar(sala.ball.global_position.distance_to(centro) < 0.04, "Colocación coincide con el clic")
	comprobar(not sala.ball.get_meta("puede_recoger"), "Colocar blanca no recoge activadores")

	# Simulamos caída en tronera: no vuelve a su posición inicial.
	sala.tiro_iniciado.emit()
	partida.reglas.contacto(1)
	sala.ball.global_position = Vector3(0, 3.4, 2.7)
	partida.registrar_caida(sala.ball)
	await process_frame
	comprobar(not sala.ball.visible and sala.ball.freeze, "Blanca embocada queda oculta")
	partida.finalizar_tiro()
	comprobar(partida.bola_en_mano and partida.reglas.turno == 1, "Falta cambia turno con bola en mano")
	await physics_frame
	partida.colocar_blanca(centro)

	# El primer contacto se registra mediante señales reales de física.
	for cuerpo in get_nodes_in_group("bolas_color"):
		cuerpo.freeze = true
	var objetivo = sala.get_node("Bolas/Ball1")
	objetivo.position = Vector3(0, 4.3161234, 0)
	objetivo.freeze = false
	sala.ball.global_position = Vector3(0.7, 4.3161234, 0)
	sala.ball.linear_velocity = Vector3.ZERO
	await physics_frame
	sala.tiro_iniciado.emit()
	sala.ball.linear_velocity = Vector3(-3, 0, 0)
	for paso in range(20):
		await physics_frame
	comprobar(partida.reglas.primer_contacto == 1, "Contacto con blanca detectado físicamente")
	# Reinicio real de escena al embocar la 8 en el saque.
	partida.reglas.saque = true
	partida.reglas.retirar(8, true)
	partida.finalizar_tiro()
	await process_frame
	await process_frame
	var nueva = current_scene
	comprobar(nueva != sala and nueva.get_node("Partida").reglas.saque, "La 8 en saque recarga la partida")
	comprobar(get_nodes_in_group("bolas_color").size() == 15, "Reinicio recupera las 15 bolas")
	var final = nueva.get_node("Partida")
	final.reglas.saque = false
	final.reglas.grupos = [1, 2]
	final.reglas.restantes.assign([8, 9])
	nueva.tiro_iniciado.emit()
	final.reglas.contacto(8)
	final.reglas.retirar(8, true)
	final.finalizar_tiro()
	comprobar(final.terminada and final.reglas.ganador == 1, "Victoria integrada al controlador")
	comprobar(not final.puede_apuntar() and final.reiniciar.visible, "Victoria bloquea tiros y ofrece nueva partida")
	comprobar(nueva.camera_mesa.is_current(), "Victoria muestra la mesa")
	print("PARTIDA TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)

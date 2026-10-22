extends SceneTree

var fallos := 0


func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	_probar.call_deferred()


func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)


func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	await process_frame
	var partida = sala.get_node("Partida")
	comprobar(partida.configuracion.visible and not partida.puede_apuntar(), "Inicio obligatorio")
	comprobar(partida.cpu.scene_file_path == "res://scenes/cpu/cpu.tscn", "CPU instanciada desde su escena")
	sala.tiro_iniciado.emit()
	comprobar(not partida.reglas.en_tiro, "El diálogo bloquea tiros")
	partida.cpu.probabilidad_error = 0.0
	partida.comenzar_partida(true)
	comprobar(partida.cpu.probabilidad_error == 0.0, "Inicio respeta ajustes del script")
	comprobar(not partida.configuracion.visible and partida.permite_input_humano(), "Jugador 1 inicia")
	sala.tiro_iniciado.emit()
	partida.reglas.contacto(1)
	for numero in [1, 2, 3, 4]:
		partida.reglas.banda(numero)
	partida.finalizar_tiro()
	comprobar(partida.reglas.turno == 2 and sala.camera_mesa.is_current(), "Cámara estática desde que comienza turno CPU")
	partida.reglas.saque = false
	partida.reglas.grupos = [1, 2]
	comprobar(not partida.permite_input_humano(), "CPU bloquea entrada humana")
	var objetivo = partida.cpu.elegir_objetivo()
	comprobar(int(objetivo.get_meta("numero")) >= 9, "CPU elige su grupo")
	partida.reglas.restantes.assign([8, 1])
	objetivo = partida.cpu.elegir_objetivo()
	comprobar(objetivo.get_meta("numero") == 8, "CPU va por la negra al terminar su grupo")
	var limpio: Dictionary = partida.cpu.aplicar_error(Vector3.RIGHT, 5.0)
	comprobar(limpio.direccion == Vector3.RIGHT and limpio.fuerza == 5.0, "Sin error conserva tiro")
	partida.cpu.probabilidad_error = 1.0
	partida.cpu.error_angulo_grados = 12.0
	partida.cpu.error_fuerza = 0.3
	partida.cpu.azar.seed = 123
	for i in range(100):
		var tiro: Dictionary = partida.cpu.aplicar_error(Vector3.RIGHT, 5.0)
		comprobar(absf(Vector3.RIGHT.signed_angle_to(tiro.direccion, Vector3.UP)) <= deg_to_rad(12.01), "Desvío acotado")
		comprobar(tiro.fuerza >= 3.5 and tiro.fuerza <= 6.5, "Fuerza acotada")
	partida.cpu.set_physics_process(false)
	for bola in get_nodes_in_group("bolas_color"):
		if bola != objetivo:
			bola.queue_free()
	objetivo.global_position = Vector3(0, 4.3161234, 0)
	objetivo.freeze = true
	await physics_frame
	await physics_frame
	partida.bola_en_mano = true
	partida._ocultar_blanca()
	await physics_frame
	partida.cpu._colocar_blanca()
	comprobar(not partida.bola_en_mano and sala.ball.visible, "CPU coloca blanca")
	comprobar(sala.camera_mesa.is_current(), "Colocar blanca no activa cámara de bola")
	var primera: Vector3 = sala.ball.global_position
	var ideal: Vector3 = objetivo.global_position - objetivo.global_position.direction_to(partida.cpu._tronera_cercana(objetivo.global_position)) * partida.cpu.distancia_colocacion
	ideal.y = primera.y
	comprobar(primera.distance_to(ideal) <= sqrt(2.0) * partida.cpu.variacion_colocacion + 0.01, "Colocación cerca del punto útil")
	partida.bola_en_mano = true
	partida._ocultar_blanca()
	await physics_frame
	partida.cpu._colocar_blanca()
	comprobar(primera.distance_to(sala.ball.global_position) > 0.001, "Colocación varía entre tiros")
	for bola in get_nodes_in_group("bolas_color") + [sala.ball]:
		bola.linear_velocity = Vector3.ZERO
		bola.angular_velocity = Vector3.ZERO
		bola.sleeping = true
	partida.cpu._physics_process(partida.cpu.demora)
	comprobar(partida.reglas.en_tiro and sala.is_waiting_for_ball, "CPU usa ciclo de tiro normal")
	comprobar(sala.camera_mesa.is_current(), "Cámara estática al disparar")
	partida.reglas.contacto(8)
	partida.finalizar_tiro()
	comprobar(partida.reglas.turno == 1 and sala.camera.is_current(), "Cámara de bola vuelve al jugador humano")
	partida.terminada = true
	partida.reglas.en_tiro = false
	sala.is_waiting_for_ball = false
	partida.cpu.disparar(Vector3.RIGHT, 3.0)
	comprobar(not partida.reglas.en_tiro, "CPU no dispara tras el final")
	partida.reiniciar_partida()
	await process_frame
	await process_frame
	comprobar(current_scene.get_node("Partida").configurando, "Reinicio vuelve a pedir rival")
	print("CPU TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)

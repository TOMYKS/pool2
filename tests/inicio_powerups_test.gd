extends SceneTree

const Reglas = preload("res://scripts/reglas_pool.gd")
var errores := 0


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func(): quit(2))
	_probar.call_deferred()


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)


func tiro(sala: Node, contacto: int, embocada := -1) -> void:
	var reglas = sala.get_node("Partida").reglas
	sala.tiro_iniciado.emit()
	reglas.contacto(contacto)
	if embocada >= 0:
		reglas.retirar(embocada, true)
	# Saque legal sin embocar; luego, estos rebotes no afectan los turnos.
	for numero in [1, 2, 3, 4]:
		reglas.banda(numero)
	reglas.finalizar_tiro()
	sala.tiro_finalizado.emit()


func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	if sala.get_node_or_null("Powerups") == null:
		var administrador = load("res://scenes/powerups.tscn").instantiate()
		administrador.name = "Powerups"
		sala.add_child(administrador)
	await process_frame
	await physics_frame
	for cuerpo in get_nodes_in_group("bolas_color") + get_nodes_in_group("blanca"):
		cuerpo.freeze = true
	var partida = sala.get_node("Partida")
	var sistema = sala.get_node("Powerups")
	sistema.probabilidad_aparicion = 1.0
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_SPACE
	tecla.pressed = true
	root.push_input(tecla)
	await process_frame
	await process_frame
	comprobar(sistema.habilitado, "Espacio habilita aunque todavía no haya grupos")
	comprobar(not is_instance_valid(sistema.activador), "No aparece en el saque")
	comprobar(sistema._estado.text.contains("asignación"), "El HUD explica la espera inicial")
	sistema._intentar_aparicion(true)
	comprobar(not is_instance_valid(sistema.activador), "Forzar no salta la introducción")
	sistema.alternar_sistema()
	sistema.alternar_sistema()
	comprobar(not is_instance_valid(sistema.activador), "Apagar y encender no salta la introducción")

	# Ambos órdenes de asignación; también cuenta el progreso con poderes apagados.
	for asignador in [1, 2]:
		partida.reglas = Reglas.new()
		var reglas = partida.reglas
		comprobar(not reglas.poderes_desbloqueados(), "Una nueva partida reinicia la espera")
		if asignador == 2:
			sistema.alternar_sistema()
		tiro(sala, 1)
		comprobar(reglas.turno == 2 and reglas.tiros_con_grupo == [false, false], "El saque no cuenta")
		tiro(sala, 1)
		tiro(sala, 9)
		comprobar(reglas.tiros_con_grupo == [false, false], "Los tiros con mesa abierta no cuentan")
		if asignador == 1:
			tiro(sala, 1)
		tiro(sala, 1, 1)
		comprobar(reglas.turno == asignador and not reglas.grupos.has(0), "Asignar mantiene el turno")
		comprobar(not reglas.poderes_desbloqueados(), "Asignar no habilita todavía el activador")
		comprobar(reglas.tiros_con_grupo == [false, false], "El tiro de asignación no cuenta")
		tiro(sala, 2, 2)
		comprobar(reglas.tiros_con_grupo[asignador - 1] and reglas.turno == asignador, "Un tiro cuenta aunque embocar conserve el turno")
		tiro(sala, 3, 3)
		comprobar(not reglas.tiros_con_grupo[2 - asignador], "Repetir tiros no cuenta por el otro jugador")
		comprobar(not is_instance_valid(sistema.activador), "Sigue sin activador durante esa racha")
		tiro(sala, 4)
		comprobar(not reglas.poderes_desbloqueados(), "Falta el tiro del otro jugador")
		if sistema.habilitado:
			comprobar(sistema._estado.text.contains("jugador %d" % (3 - asignador)), "HUD indica quién falta")
		sistema._intentar_aparicion(true)
		comprobar(not is_instance_valid(sistema.activador), "Ni forzando aparece si solo tiró un jugador con grupo")
		tiro(sala, 9, 9)
		comprobar(reglas.poderes_desbloqueados() and reglas.turno == 3 - asignador, "El primer tiro del segundo jugador desbloquea aunque siga su turno")
		comprobar(is_instance_valid(sistema.activador) == sistema.habilitado, "Puede aparecer al acabar ese mismo tiro si el sistema está encendido")
		sistema._quitar_activador()
		# La probabilidad sigue aplicando después del desbloqueo.
		sistema.probabilidad_aparicion = 0.0
		tiro(sala, 4)
		comprobar(reglas.poderes_desbloqueados(), "Una falta posterior no reinicia la espera")
		comprobar(not is_instance_valid(sistema.activador), "Desbloquear no fuerza el sorteo ni enciende el sistema")
		if not sistema.habilitado:
			sistema.alternar_sistema()
		comprobar(not is_instance_valid(sistema.activador), "Encender respeta la probabilidad")
		sistema.probabilidad_aparicion = 1.0
		tiro(sala, 4)
		comprobar(is_instance_valid(sistema.activador), "Tras la espera aparece al terminar un tiro")
		sistema.alternar_sistema()
		comprobar(not is_instance_valid(sistema.activador), "Apagar elimina el activador")
		sistema.alternar_sistema()
		comprobar(is_instance_valid(sistema.activador), "Volver a encender conserva el progreso")
		sistema._quitar_activador()
		await process_frame

	partida.terminada = true
	sistema._intentar_aparicion(true)
	comprobar(not is_instance_valid(sistema.activador), "No aparece después del final de la partida")
	print("INICIO POWERUPS TEST: ", errores, " errores")
	quit(1 if errores else 0)

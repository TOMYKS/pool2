extends SceneTree

const Reglas = preload("res://scripts/reglas_pool.gd")
var fallos := 0

func _initialize() -> void:
	create_timer(25).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func reglas_para(jugador: int, listo: bool):
	var reglas = Reglas.new()
	reglas.saque = false
	reglas.turno = jugador
	reglas.grupos = [1, 2]
	if listo:
		reglas.restantes.assign([8, 9, 10] if jugador == 1 else [1, 2, 8])
	reglas.iniciar_tiro()
	return reglas

func _probar() -> void:
	for jugador in [1, 2]:
		var propia := 1 if jugador == 1 else 9
		var rival := 10 if jugador == 1 else 2
		var r = reglas_para(jugador, false)
		r.contacto(propia, true)
		r.contacto(propia + 1)
		comprobar(r.primer_contacto == 8, "La primera falsa 8 no se reemplaza por un contacto posterior")
		comprobar(r.finalizar_tiro().bola_en_mano and r.turno == 3 - jugador, "Falsa 8 propia primero es falta")
		r = reglas_para(jugador, false)
		r.contacto(propia)
		r.contacto(rival, true)
		comprobar(not r.finalizar_tiro().bola_en_mano, "Tocar una falsa 8 después de la propia es válido")
		r = reglas_para(jugador, false)
		r.contacto(propia, true)
		r.retirar(propia, true, true)
		comprobar(r.finalizar_tiro().ganador == 3 - jugador, "Embocar una falsa 8 anticipadamente pierde")
		r = reglas_para(jugador, true)
		r.contacto(rival, true)
		comprobar(not r.finalizar_tiro().bola_en_mano, "Si solo queda la 8, tocar la falsa sin embocar es válido")
		for falta in ["ninguna", "blanca_antes", "blanca_despues", "contacto_incorrecto", "fuera"]:
			r = reglas_para(jugador, true)
			r.contacto(rival, falta != "contacto_incorrecto")
			if falta == "blanca_antes":
				r.retirar(0, true)
			r.retirar(rival, true, true)
			if falta == "blanca_despues":
				r.retirar(0, true)
			if falta == "fuera":
				r.retirar(8, false)
			comprobar(r.finalizar_tiro().ganador == (jugador if falta == "ninguna" else 3 - jugador), "Ganar con falsa 8 exige tiro legal: " + falta)
		r = reglas_para(jugador, false)
		r.restantes.assign([propia, 8, rival])
		r.contacto(propia)
		r.retirar(propia, true)
		r.retirar(rival, true, true)
		comprobar(r.finalizar_tiro().ganador == 3 - jugador, "La última propia y una falsa 8 en el mismo tiro no ganan")
		r = reglas_para(jugador, true)
		r.contacto(rival) # Ya recuperó el aspecto de su grupo.
		r.retirar(rival, true)
		comprobar(r.finalizar_tiro().bola_en_mano and r.ganador == 0, "Una bola restaurada deja de valer como 8")
		await _contacto_fisico(jugador, false)
		await _contacto_fisico(jugador, true)
	var abierta = Reglas.new()
	abierta.saque = false
	abierta.iniciar_tiro()
	abierta.contacto(4, true)
	comprobar(abierta.finalizar_tiro().bola_en_mano, "Una falsa 8 primero también es falta en mesa abierta")
	print("OCHOS CONTACTOS TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)

func _contacto_fisico(jugador: int, listo: bool) -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	var poder = load("res://scenes/ochos.tscn").instantiate()
	sala.add_child(poder)
	await process_frame
	var partida = sala.get_node("Partida")
	partida.reglas.saque = false
	partida.reglas.grupos = [1, 2]
	partida.reglas.turno = jugador
	for bola in get_nodes_in_group("bolas_color"):
		bola.freeze = true
		var numero := int(bola.get_meta("numero"))
		if listo and partida.reglas.grupo_de(numero) == jugador:
			partida.reglas.restantes.erase(numero)
			bola.queue_free()
	await process_frame
	poder.activar_ochos()
	var objetivo: RigidBody3D
	for bola in get_nodes_in_group("bolas_color"):
		var numero := int(bola.get_meta("numero"))
		var grupo: int = partida.reglas.grupo_de(numero)
		if numero != 8 and bola.get_meta("ocho_mortal", false) and grupo == (3 - jugador if listo else jugador):
			objetivo = bola
			break
	comprobar(objetivo != null, "Debe existir una falsa 8 para probar")
	if objetivo == null:
		sala.queue_free()
		await process_frame
		return
	objetivo.global_position = Vector3(0, 4.3261234, 0)
	objetivo.freeze = false
	sala.ball.freeze = true
	sala.ball.global_position = Vector3(0.7, 4.3261234, 0)
	await physics_frame
	await physics_frame
	sala.ball.freeze = false
	sala.ball.linear_velocity = Vector3(-3, 0, 0)
	sala.tiro_iniciado.emit()
	for paso in range(20):
		await physics_frame
	comprobar(partida.reglas.primer_contacto == 8, "Colisión real registra una falsa como 8")
	if listo:
		objetivo.global_position = Vector3(0, 3.4, 2.7)
		partida.registrar_caida(objetivo)
	# Simula el vencimiento antes de que se resuelvan las reglas.
	poder.desactivar_ochos()
	partida.finalizar_tiro()
	if listo:
		comprobar(partida.terminada and partida.reglas.ganador == jugador, "Ganar con una falsa 8 del rival aun si vence el poder")
	else:
		comprobar(partida.bola_en_mano and partida.reglas.turno == 3 - jugador, "Contacto real con falsa propia da bola en mano aun si vence el poder")
	sala.queue_free()
	await process_frame

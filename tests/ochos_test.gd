extends SceneTree

const Reglas = preload("res://scripts/reglas_pool.gd")
var fallos := 0

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func visibles(grupo: int) -> Array[Node]:
	var resultado: Array[Node] = []
	for bola in get_nodes_in_group("bolas_color"):
		if not bola.is_queued_for_deletion() and not bola.get_meta("ocho_mortal", false):
			var numero := int(bola.get_meta("numero"))
			if (grupo == 1 and numero < 8) or (grupo == 2 and numero > 8):
				resultado.append(bola)
	return resultado

func caer(partida: Node, bola: RigidBody3D) -> void:
	bola.global_position = Vector3(0, 3.4, 2.7)
	partida.registrar_caida(bola)

func _probar() -> void:
	for jugador in [1, 2]:
		var sala = load("res://scenes/sala.tscn").instantiate()
		root.add_child(sala)
		current_scene = sala
		var poder = load("res://scenes/ochos.tscn").instantiate()
		sala.add_child(poder)
		await process_frame
		await physics_frame
		var partida = sala.get_node("Partida")
		partida.reglas.saque = false
		partida.reglas.grupos = [1, 2]
		partida.reglas.turno = jugador
		var originales := {}
		for bola in get_nodes_in_group("bolas_color"):
			bola.freeze = true
			originales[bola.get_instance_id()] = bola.get_child(0).mesh
		sala.ball.freeze = true
		poder._azar.seed = 27
		poder.activar_ochos()
		poder.activar_ochos()
		comprobar(poder._originales.size() == 15, "Activar dos veces no duplica el estado")
		comprobar(visibles(1).size() == 1 and visibles(2).size() == 1, "Una lisa y una rayada visibles")
		comprobar(not sala.ball.has_meta("ocho_mortal"), "La blanca queda intacta")
		var negras := 0
		for bola in get_nodes_in_group("bolas_color"):
			if bola.get_meta("ocho_mortal", false):
				negras += 1
				comprobar(bola.get_child(0).mesh == poder.MALLA_OCHO, "Todas las peligrosas usan el modelo de la 8")
		comprobar(negras == 13, "Trece bolas negras con mesa completa")
		if "--preview" in OS.get_cmdline_user_args():
			var indice := 0
			for bola in get_nodes_in_group("bolas_color"):
				bola.global_position = Vector3(-1.8 + (indice % 5) * 0.7, 4.32, -0.7 + int(indice / 5.0) * 0.7)
				indice += 1
			sala.camera_mesa.global_position = Vector3(0, 7, 4.8)
			sala.camera_mesa.look_at(Vector3(-0.4, 4.32, 0))
			sala.camera_mesa.make_current()
			for paso in range(10):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("TEMP") + "/pool2-ochos.png")
			quit()
			return
		# Se puede encadenar el grupo completo, revelando una por vez.
		for paso in range(7):
			var segura: RigidBody3D = visibles(jugador)[0]
			sala.tiro_iniciado.emit()
			partida.reglas.contacto(int(segura.get_meta("numero")))
			caer(partida, segura)
			await process_frame
			comprobar(visibles(jugador).size() == (1 if paso < 6 else 0), "Revelar siguiente hasta agotar el grupo")
			comprobar(visibles(3 - jugador).size() == 1, "La bola visible del rival no cambia")
			partida.finalizar_tiro()
			comprobar(not partida.terminada and not partida.bola_en_mano and partida.reglas.turno == jugador, "Embocar la visible propia conserva turno")
		# Aunque ya pueda jugar la 8, embocarla durante el efecto hace perder.
		sala.tiro_iniciado.emit()
		partida.reglas.contacto(8)
		caer(partida, sala.get_node("Bolas/Ball8"))
		poder.desactivar_ochos()
		for bola in get_nodes_in_group("bolas_color"):
			if not bola.is_queued_for_deletion():
				comprobar(not bola.has_meta("ocho_mortal") and bola.get_child(0).mesh == originales[bola.get_instance_id()], "Restaurar exactamente cada modelo original")
		partida.finalizar_tiro()
		comprobar(partida.terminada and partida.reglas.ganador == 3 - jugador, "La derrota sobrevive al fin del efecto, para ambos jugadores")
		comprobar(partida.detalle.text.contains("Ochos malditos"), "HUD explica el motivo de derrota")
		sala.queue_free()
		await process_frame

	await _casos_limite()
	# Reglas puras: cualquier número transformado es mortal; importa el estado
	# al caer, no el número original ni el orden respecto de la blanca.
	for numero in [2, 8, 10]:
		for saque in [true, false]:
			for blanca_primero in [true, false]:
				var reglas = Reglas.new()
				reglas.saque = saque
				reglas.iniciar_tiro()
				reglas.contacto(1)
				if blanca_primero:
					reglas.retirar(0, true)
				reglas.retirar(numero, true, true)
				if not blanca_primero:
					reglas.retirar(0, true)
				comprobar(reglas.finalizar_tiro().get("ganador", 0) == 2, "Cualquier 8 mortal pierde incluso en saque o con blanca")
	var reglas = Reglas.new()
	reglas.saque = false
	reglas.grupos = [1, 2]
	reglas.iniciar_tiro()
	reglas.contacto(2)
	reglas.retirar(2, false, true)
	var resultado: Dictionary = reglas.finalizar_tiro()
	comprobar(resultado.get("bola_en_mano", false) and reglas.ganador == 0, "Salir de la mesa conserva la falta habitual, no es embocar")
	print("OCHOS TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)


func _casos_limite() -> void:
	for caso in ["convertida", "visible_primero", "negra_primero", "vence", "rival"]:
		var sala = load("res://scenes/sala.tscn").instantiate()
		root.add_child(sala)
		current_scene = sala
		var poder = load("res://scenes/ochos.tscn").instantiate()
		sala.add_child(poder)
		await process_frame
		var partida = sala.get_node("Partida")
		partida.reglas.saque = false
		partida.reglas.grupos = [1, 2]
		for bola in get_nodes_in_group("bolas_color") + get_nodes_in_group("blanca"):
			bola.freeze = true
		poder.activar_ochos()
		var segura: RigidBody3D = visibles(1)[0]
		var rival: RigidBody3D = visibles(2)[0]
		var convertida: RigidBody3D
		for bola in get_nodes_in_group("bolas_color"):
			if bola.get_meta("ocho_mortal", false) and int(bola.get_meta("numero")) != 8:
				convertida = bola
				break
		sala.tiro_iniciado.emit()
		partida.reglas.contacto(int(segura.get_meta("numero")))
		if caso == "vence":
			caer(partida, segura)
			poder.desactivar_ochos()
			await process_frame
			comprobar(visibles(1).size() == 6 and visibles(2).size() == 7, "Revelación pendiente no altera el estado después de vencer")
			partida.finalizar_tiro()
			comprobar(not partida.terminada and not partida.bola_en_mano, "Visible al vencer sigue siendo legal")
		elif caso == "rival":
			caer(partida, rival)
			await process_frame
			comprobar(visibles(2).is_empty(), "Embocar la visible rival no desbloquea otra")
			partida.finalizar_tiro()
			comprobar(not partida.terminada and partida.reglas.turno == 2, "Visible rival mantiene las reglas de cambio de turno")
		else:
			if caso == "visible_primero":
				caer(partida, segura)
			caer(partida, convertida)
			if caso == "negra_primero":
				caer(partida, segura)
			await process_frame
			if caso != "convertida":
				comprobar(visibles(1).is_empty(), "No revelar otra si en el mismo paso cayó una mortal")
			poder.desactivar_ochos()
			partida.finalizar_tiro()
			comprobar(partida.terminada and partida.reglas.ganador == 2, "Una bola convertida causa derrota, incluso junto a una visible")
		sala.queue_free()
		await process_frame

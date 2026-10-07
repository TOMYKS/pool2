extends SceneTree

var fallos := 0

func _initialize() -> void:
	create_timer(50).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)

func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	if sala.get_node_or_null("Powerups") == null:
		var administrador = load("res://scenes/powerups.tscn").instantiate()
		administrador.name = "Powerups"
		sala.add_child(administrador)
	await process_frame
	await physics_frame
	var sistema = sala.get_node("Powerups")
	var poder = sistema._controladores[sistema.TipoPoder.TRONERAS]
	comprobar(not poder.is_processing_input(), "Administrador conserva el control de Espacio")
	poder.patron = poder.Patron.TODAS
	poder.activar_troneras()
	if "--preview" in OS.get_cmdline_user_args():
		sala.camera_mesa.make_current()
		for i in range(10):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP") + "/pool2-troneras.png")
		sala.camera_mesa.global_position = Vector3(-3, 5.7, 4.1)
		sala.camera_mesa.look_at(Vector3(-4.7, 4.326, 2.3))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP") + "/pool2-troneras-detalle.png")
		quit()
		return
	comprobar(poder.seleccionadas.size() == 6, "TODAS selecciona seis troneras")
	poder.desactivar_troneras()
	poder._azar.seed = 52
	var cantidades := {}
	for i in range(120):
		poder.patron = poder.Patron.ALEATORIO
		var seleccion: Array[int] = poder._sortear_troneras()
		cantidades[seleccion.size()] = true
		var unicas := {}
		for indice in seleccion:
			comprobar(indice >= 0 and indice < 6 and not unicas.has(indice), "Sorteo sin índices repetidos o inválidos")
			unicas[indice] = true
	comprobar(cantidades.size() == 6, "El azar permite desde una hasta seis tapas")
	for i in range(12):
		poder.patron = poder.Patron.UN_LADO
		comprobar(poder.LADOS.has(poder._sortear_troneras()), "UN_LADO elige un lado completo")
	# La entrada no se cierra atravesando una bola y se cierra al despejarse.
	var blanca: RigidBody3D = sala.ball
	blanca.freeze = true
	blanca.global_position = poder._tapas[1].global_position
	poder.patron = poder.Patron.TODAS
	poder.activar_troneras()
	comprobar(poder._tapas[1].get_node("Colision").disabled, "Bola en la entrada demora el cierre")
	blanca.global_position = Vector3(2, 4.32, 0)
	await physics_frame
	await physics_frame
	comprobar(not poder._tapas[1].get_node("Colision").disabled, "Entrada despejada se cierra")
	# Expiración real por el administrador, una sola vez por tiro.
	sistema.habilitado = true
	sistema.poder_actual = sistema.TipoPoder.TRONERAS
	sistema.tiros_restantes = 1
	sistema._tiro_recogida = 0
	sala.tiro_iniciado.emit()
	comprobar(sistema.preparar_fin_tiro(), "Vencimiento avisa que cambió la física antes de resolver el tiro")
	comprobar(not poder.powerup_troneras_activo and not sistema.preparar_fin_tiro(), "Vencimiento desactiva una sola vez")
	sala.get_node("Partida").reglas.en_tiro = false
	sistema.habilitado = false
	for bola in get_nodes_in_group("bolas_color"):
		bola.queue_free()
	await process_frame
	var choques := {}
	blanca.body_entered.connect(func(body):
		if body.is_in_group("bandas_powerup"):
			choques[body.get_instance_id()] = true)
	# Física real: las seis entradas rebotan cerradas y permiten caer abiertas.
	for cerrada in [true, false]:
		if cerrada:
			poder.activar_troneras()
		else:
			poder.desactivar_troneras()
		for trayectoria in range(18 if cerrada else 6):
			var indice := int(trayectoria / 3.0) if cerrada else trayectoria
			blanca.freeze = true
			var centro: Vector2 = poder.CENTROS[indice]
			var direccion := Vector3(0, 0, signf(centro.y)) if centro.x == 0 else Vector3(signf(centro.x), 0, signf(centro.y)).normalized()
			var inicio := Vector3(centro.x, 4.3261234, centro.y) - direccion * 0.75
			if cerrada:
				inicio += direccion.cross(Vector3.UP) * (trayectoria % 3 - 1) * 0.25
			blanca.global_position = inicio
			blanca.linear_velocity = Vector3.ZERO
			blanca.angular_velocity = Vector3.ZERO
			await physics_frame
			await physics_frame
			blanca.freeze = false
			blanca.sleeping = false
			blanca.linear_velocity = direccion * 3.0
			choques.clear()
			var reboto := false
			var cayo := false
			for paso in range(100):
				await physics_frame
				reboto = reboto or blanca.linear_velocity.dot(direccion) < -0.1
				cayo = cayo or blanca.global_position.y < 3.55
				if cayo or (cerrada and reboto):
					break
			if cerrada:
				comprobar(reboto and not cayo and choques.has(poder._tapas[indice].get_instance_id()), "Tronera %d cerrada debe rebotar contra la tapa" % indice)
			else:
				comprobar(cayo, "Tronera %d abierta debe permitir embocar" % indice)
	print("TRONERAS TEST: ", fallos, " fallos")
	sala.queue_free()
	await process_frame
	quit(0 if fallos == 0 else 1)

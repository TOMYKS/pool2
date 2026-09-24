extends SceneTree

var errores := 0

func _initialize() -> void:
	create_timer(20.0).timeout.connect(func(): quit(2))
	call_deferred("_probar")

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)

func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	await process_frame
	await physics_frame
	var sistema = sala.get_node("Powerups")
	comprobar(sistema._listo, "Administrador preparado")
	comprobar(not sistema.habilitado, "Arranca apagado")
	for controlador in sistema._controladores.values():
		comprobar(not controlador.is_processing_input(), "Espacio solo controla el sistema")
	var bola = sala.get_node("Bolas/Ball1")
	bola.mass = 1.23
	var fisica = bola.physics_material_override
	var visual = bola.get_child(0)
	var material = visual.get_active_material(0)
	var color_original: Color = material.albedo_color
	var radio_original: float = bola.get_node("CollisionShape3D").shape.radius
	# Aislamos el ciclo de turnos del movimiento de la mesa.
	for cuerpo in get_nodes_in_group("bolas_color") + get_nodes_in_group("blanca"):
		cuerpo.freeze = true
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_SPACE
	tecla.pressed = true
	root.push_input(tecla)
	await process_frame
	await process_frame
	comprobar(sistema.habilitado, "Espacio enciende el sistema")
	comprobar(is_instance_valid(sistema.activador), "Aparece activador genérico")
	if not is_instance_valid(sistema.activador):
		quit(1)
		return
	comprobar(sistema.poder_actual == -1, "No se sortea antes del contacto")
	sistema.activador._al_entrar(bola)
	comprobar(not sistema.activador.consumido, "Una bola de color no recoge")
	sistema.probabilidad_aparicion = 1.0
	sistema._azar.seed = 42
	var vistos := {}
	for ciclo in range(32):
		if not is_instance_valid(sistema.activador):
			sistema._intentar_aparicion(true)
		if not is_instance_valid(sistema.activador):
			comprobar(false, "Debe aparecer un nuevo activador")
			break
		sala.tiro_iniciado.emit()
		var punto: Vector3 = sistema.activador.global_position
		# Comprueba el barrido de una blanca que cruza el objeto entre frames.
		sistema.activador.comprobar_recorrido(sala.ball, punto - Vector3(0.5, 0, 0), punto + Vector3(0.5, 0, 0))
		sistema.activador._al_entrar(sala.ball)
		await process_frame
		comprobar(sistema.poder_actual != -1, "Recoger sortea un poder")
		vistos[sistema.poder_actual] = true
		comprobar(not is_instance_valid(sistema.activador), "Activador consumido una sola vez")
		var duracion: int = sistema.tiros_restantes
		sala.tiro_finalizado.emit()
		comprobar(sistema.tiros_restantes == duracion, "No descuenta el tiro de recogida")
		for tiro in range(duracion):
			sala.tiro_iniciado.emit()
			sala.tiro_finalizado.emit()
		comprobar(sistema.poder_actual == -1, "El poder vence tras sus tiros completos")
		comprobar(is_equal_approx(bola.mass, 1.23), "Restaura masa real")
		comprobar(bola.physics_material_override == fisica, "Restaura material físico original")
		comprobar(visual.get_active_material(0) == material and material.albedo_color == color_original, "Restaura materiales visuales sin mutar recursos")
		comprobar(is_equal_approx(bola.get_node("CollisionShape3D").shape.radius, radio_original), "Restaura tamaño")
	comprobar(vistos.size() == 4, "El sorteo incluye los cuatro poderes")
	# Apagar durante un efecto también restaura y elimina el activador.
	sistema.activador._al_entrar(sala.ball)
	await process_frame
	root.push_input(tecla)
	await process_frame
	await process_frame
	comprobar(not sistema.habilitado and sistema.poder_actual == -1, "Espacio apaga y cancela el efecto")
	comprobar(not is_instance_valid(sistema.activador), "Sin activador al apagar")
	comprobar(is_equal_approx(bola.mass, 1.23) and bola.physics_material_override == fisica, "Apagar restaura física")
	print("POWERUPS TEST: ", errores, " errores; poderes sorteados: ", vistos.keys())
	quit(1 if errores else 0)

extends SceneTree

var errores := 0
var casos := 0

func _initialize() -> void:
	create_timer(180).timeout.connect(func(): quit(2))
	probar.call_deferred()

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)

func probar() -> void:
	for sitio in [Vector2.ZERO, Vector2(4.6, 0), Vector2(4.7, 2.3)]:
		await caso("REBOTE", 1, sitio, 1)
	# Que un tiro termine no debe quitar un poder al que aún le queda duración.
	await caso("REBOTE", 1, Vector2.ZERO, 2)
	for factor in [2, 3]:
		for sitio in [Vector2.ZERO, Vector2(0, 2.6), Vector2(4.9, 2.42)]:
			await caso("GRANDES", factor, sitio, 1)
	print("FIN TIRO PODERES: ", errores, " errores en ", casos, " casos")
	quit(1 if errores else 0)

func caso(tipo: String, factor: int, sitio: Vector2, duracion: int) -> void:
	casos += 1
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	for i in range(3):
		await process_frame
	var p = sala.get_node("Partida")
	p.comenzar_partida(false)
	p.con_powerups = true
	sala.camera_transition_seconds = 0.0
	paused = false
	sala.ball.freeze = true
	var bola: RigidBody3D = sala.get_node("Bolas/Ball1")
	for otra in get_nodes_in_group("bolas_color"):
		if otra != bola:
			otra.queue_free()
	await process_frame
	bola.position = Vector3(sitio.x, p.ALTURA_PANO + bola.get_node("CollisionShape3D").shape.radius + 0.01, sitio.y)
	bola.linear_velocity = Vector3.ZERO
	bola.angular_velocity = Vector3.ZERO
	var sistema = sala.get_node("Powerups")
	var clave: int = sistema.TipoPoder[tipo]
	sistema.habilitado = true
	sistema.probabilidad_aparicion = 0.0
	if tipo == "GRANDES":
		sistema._controladores[clave].multiplicador_tamano = factor
	sistema._guardar_originales()
	sistema._controladores[clave].call(sistema.PODERES[clave]["activar"])
	sistema.poder_actual = clave
	sistema.tiros_restantes = duracion
	sala.tiro_iniciado.emit()
	p.reglas.contacto(1)
	sala.is_waiting_for_ball = true
	sala.time_since_hit = 0.0
	for i in range(Engine.physics_ticks_per_second * 10):
		await physics_frame
		if not sala.is_waiting_for_ball:
			break
	var detalle := "%s x%d en %s" % [tipo, factor, sitio]
	comprobar(not sala.is_waiting_for_ball and not p.reglas.en_tiro, "Cerrar el tiro sin quedar esperando: " + detalle)
	comprobar(sistema.tiros_restantes == duracion - 1, "Descontar exactamente un tiro de duración: " + detalle)
	comprobar(sistema.poder_actual == (-1 if duracion == 1 else clave), "Restaurar el poder solo cuando corresponda: " + detalle)
	if duracion == 2 and is_instance_valid(bola):
		# El reposo no congela la física: el siguiente choque vuelve a moverla.
		bola.apply_central_impulse(Vector3.RIGHT * 0.6)
		for i in range(5):
			await physics_frame
		comprobar(not bola.sleeping and bola.linear_velocity.x > 0.1, "La bola con Rebote extra debe despertar con un nuevo golpe")
	if tipo == "GRANDES" and sitio == Vector2(4.9, 2.42):
		comprobar(not is_instance_valid(bola), "Al encoger, completar y registrar la caída en la misma tronera y tiro")
	sala.queue_free()
	await process_frame

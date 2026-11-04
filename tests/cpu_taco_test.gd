extends SceneTree
var errores := 0
func _initialize() -> void:
	probar.call_deferred()
func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		errores += 1
		push_error(mensaje)
func probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	await process_frame
	await process_frame
	var p = sala.get_node("Partida")
	p.comenzar_partida(true)
	paused = false
	p.reglas.turno = 2
	p.reglas.saque = false
	var cpu = p.cpu
	cpu.demora = 1000.0
	for bola in get_nodes_in_group("bolas_color"):
		bola.freeze = true
	var tiros := [0]
	sala.tiro_iniciado.connect(func(): tiros[0] += 1)
	cpu.disparar(Vector3.LEFT, 10.0)
	cpu.disparar(Vector3.LEFT, 10.0)
	comprobar(cpu.animando_golpe and sala.taco.visible, "La CPU debe mostrar el taco y evitar iniciar dos animaciones")
	for i in range(20):
		await process_frame
	comprobar(tiros[0] == 0 and sala.ball.linear_velocity.length() < 0.06, "Retirar el taco no debe mover la blanca")
	var posicion: Vector3 = sala.taco.global_position
	p.configuracion.abrir_pausa()
	for i in range(30):
		await process_frame
	comprobar(sala.taco.global_position.is_equal_approx(posicion) and tiros[0] == 0, "La pausa debe congelar la animación antes del impacto")
	p.configuracion.continuar()
	var max_distancia := 0.0
	var min_distancia := INF
	for i in range(120):
		await process_frame
		if sala.taco.visible:
			var distancia: float = sala.taco.global_position.distance_to(sala.ball.global_position)
			max_distancia = maxf(max_distancia, distancia)
			min_distancia = minf(min_distancia, distancia)
	comprobar(max_distancia > 0.5 and min_distancia < 0.35, "El taco debe retirarse y después avanzar hasta la blanca")
	comprobar(tiros[0] == 1 and not sala.taco.visible and sala.is_waiting_for_ball, "Al contactar debe iniciar exactamente un tiro y ocultar el taco")
	sala.ball.linear_velocity = Vector3.ZERO
	sala.ball.angular_velocity = Vector3.ZERO
	sala.is_waiting_for_ball = false
	p.reglas.en_tiro = false
	cpu.disparar(Vector3.LEFT, 10.0)
	p.terminada = true
	for i in range(120):
		await process_frame
	comprobar(tiros[0] == 1 and not sala.taco.visible and not cpu.animando_golpe, "Terminar la partida durante la animación debe cancelar el golpe")
	sala.queue_free()
	await process_frame
	print("CPU TACO: ", errores, " errores")
	quit(1 if errores else 0)

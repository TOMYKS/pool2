extends SceneTree

var errores := 0

func _initialize() -> void:
	create_timer(20).timeout.connect(func(): quit(2))
	probar.call_deferred()

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)

func probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	for i in range(3):
		await process_frame
	var p = sala.get_node("Partida")
	sala.camera_transition_seconds = 0.0
	p.comenzar_partida(false)
	paused = false
	for bola in get_nodes_in_group("bolas_color"):
		bola.freeze = true
	var altura: float = p.ALTURA_PANO + sala.ball_radius + 0.01
	var colocaciones := 0
	# Labios de troneras y lugares junto a banda que no deben prohibirse.
	for z in [-2.41, 2.42]:
		for x in [-4.85, -4.7, -0.2, 0.0, 0.2, 4.7, 4.85]:
			p._ocultar_blanca()
			p.bola_en_mano = true
			var punto := Vector3(x, altura, z)
			if not p.posicion_valida(punto):
				continue # Conservar las colisiones reales de cada entrada.
			comprobar(p.colocar_blanca(punto), "Permitir un borde sin solapamientos")
			for i in range(Engine.physics_ticks_per_second):
				await physics_frame
			comprobar(sala.ball.freeze and sala.ball.global_position.is_equal_approx(punto), "La blanca debe conservar exactamente el lugar elegido antes del golpe")
			colocaciones += 1
	comprobar(colocaciones >= 7, "Permitir los bordes de tronera que antes estaban disponibles")
	# Validar un golpe humano con consulta de contacto contra la bola fija.
	p.bola_en_mano = true
	comprobar(p.colocar_blanca(Vector3(0, altura, 0)), "Colocar para preparar el taco humano")
	await physics_frame
	sala.camera.global_position = sala.ball.global_position + Vector3(1, 0.1, 0)
	sala.impact_point_global = sala.ball.global_position + Vector3.RIGHT * sala.ball_radius
	sala.setup_cue_stick()
	var retirar := InputEventMouseMotion.new()
	retirar.relative = Vector2(0, 10)
	sala._input(retirar)
	comprobar(sala.ball.freeze, "Retirar el taco no debe liberar la blanca")
	sala.cancelar_apuntado()
	comprobar(sala.ball.freeze, "Cancelar el apuntado debe conservar la blanca colocada")
	sala.setup_cue_stick()
	sala._input(retirar)
	var golpear := InputEventMouseMotion.new()
	golpear.relative = Vector2(0, -80)
	sala._input(golpear)
	comprobar(not sala.ball.freeze and p.reglas.en_tiro, "El contacto del taco humano debe liberar la blanca e iniciar el tiro")
	await physics_frame
	comprobar(sala.ball.linear_velocity.length() > 0.1, "El golpe humano no debe perder su impulso al liberar la bola")
	# Validar el impacto real de la CPU y una caída normal posterior.
	sala.is_waiting_for_ball = false
	p.reglas.en_tiro = false
	p.jugador_2_cpu = true
	p.reglas.turno = 2
	p.cpu.demora = 1000.0
	p._ocultar_blanca()
	p.bola_en_mano = true
	comprobar(p.colocar_blanca(Vector3(0, altura, 2.42)), "Permitir colocar la blanca en el borde de la tronera central")
	p.cpu.disparar(Vector3.BACK, 6.0)
	for i in range(30):
		await physics_frame
	comprobar(sala.ball.freeze, "La animación previa de la CPU debe conservar la posición")
	var liberada := false
	var cayo := false
	for i in range(Engine.physics_ticks_per_second * 2):
		await physics_frame
		liberada = liberada or not sala.ball.freeze
		cayo = cayo or sala.ball.position.y < p.ALTURA_PANO - 0.2
	comprobar(liberada and cayo, "El golpe CPU debe liberar la blanca y permitir su caída normal")
	sala.queue_free()
	await process_frame
	print("BOLA EN MANO: ", errores, " errores; ", colocaciones, " colocaciones estables, cancelación, golpe humano y golpe CPU con caída")
	quit(1 if errores else 0)

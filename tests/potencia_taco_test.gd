extends SceneTree

var fallos := 0

func _initialize() -> void:
	create_timer(20).timeout.connect(func(): quit(2))
	_probar.call_deferred()

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func mover(sala: Node, pixeles: float) -> void:
	var evento := InputEventMouseMotion.new()
	evento.relative.y = pixeles
	sala._input(evento)

func tiro(retiro: float, pasos: int, pausa := false, invertir := false) -> float:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	sala.partida.comenzar_partida(false)
	await physics_frame
	await physics_frame
	var hacia: Vector3 = sala.ball.global_position - sala.camera.global_position
	hacia.y = 0
	hacia = hacia.normalized()
	sala.impact_point_global = sala.ball.global_position - hacia * sala.ball_radius
	sala.setup_cue_stick()
	mover(sala, retiro)
	comprobar(sala._recorrido_golpe == 0.0, "Retroceder no acumula fuerza")
	if pausa or invertir:
		mover(sala, -80)
		comprobar(not sala.partida.reglas.en_tiro, "Se puede frenar antes de tocar la bola")
		if pausa:
			sala._process(sala.cue_stop_seconds + 0.01)
		else:
			mover(sala, 1)
		comprobar(sala._recorrido_golpe == 0.0, "Frenar o invertir reinicia la potencia")
	for i in range(pasos):
		mover(sala, -1000.0 / pasos)
		if sala.partida.reglas.en_tiro:
			break
	comprobar(sala.partida.reglas.en_tiro, "El golpe alcanza la blanca")
	var potencia: float = sala._potencia_del_recorrido()
	sala.queue_free()
	await process_frame
	return potencia

func _probar() -> void:
	var suave := await tiro(0, 1)
	var medio := await tiro(40, 1)
	var fuerte := await tiro(1000, 1)
	var dividido := await tiro(1000, 100)
	var frenado := await tiro(1000, 1, true)
	var invertido := await tiro(1000, 1, false, true)
	comprobar(suave < 2.0 and medio > suave and medio < 12.0 and fuerte > 18.0, "Rango suave, medio y fuerte controlable")
	comprobar(absf(fuerte - dividido) < 0.2, "Mismo recorrido da igual potencia con distinto movimiento de mouse")
	comprobar(frenado < 3.0 and invertido < 3.0, "Golpe final corto tras frenar o retroceder es suave")
	print("POTENCIA TACO TEST: ", fallos, " fallos; suave=", suave, " medio=", medio, " fuerte=", fuerte, " frenado=", frenado)
	quit(0 if fallos == 0 else 1)

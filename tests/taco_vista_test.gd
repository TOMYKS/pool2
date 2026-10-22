extends SceneTree

var fallos := 0

func _initialize() -> void:
	create_timer(15).timeout.connect(func(): quit(2))
	_probar.call_deferred()

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	sala.partida.comenzar_partida(false)
	await physics_frame
	await physics_frame
	var pivote = sala.get_node("Pivot")
	comprobar(is_equal_approx(pivote.spring_arm.spring_length, 2.8), "Zoom inicial más lejano")
	comprobar(is_equal_approx(pivote.rotation.x, deg_to_rad(-18.0)), "Vista inicial hacia abajo")
	# Aislar el brazo y cruzar el taco por su trayectoria real de colisión.
	var transformacion: Transform3D = pivote.global_transform
	var taco_original: Transform3D = sala.taco.global_transform
	pivote.set_process(false)
	pivote.global_position = Vector3(0, 20, 0)
	var brazo: SpringArm3D = pivote.spring_arm
	sala.taco.global_transform = Transform3D(brazo.global_basis, brazo.to_global(Vector3(0, 0, 1.08322549)))
	for i in range(3):
		await physics_frame
	comprobar(is_equal_approx(brazo.get_hit_length(), brazo.spring_length), "Taco no acerca la cámara")
	brazo.remove_excluded_object(sala.taco.get_rid())
	for i in range(3):
		await physics_frame
	comprobar(brazo.get_hit_length() < 1.5, "Sin exclusión se reproduce la colisión del taco")
	brazo.add_excluded_object(sala.taco.get_rid())
	for i in range(3):
		await physics_frame
	comprobar(is_equal_approx(brazo.get_hit_length(), brazo.spring_length), "Excluir taco recupera distancia completa")
	sala.taco.global_transform = taco_original
	pivote.global_transform = transformacion
	pivote.set_process(true)
	for i in range(3):
		await physics_frame
	var hacia: Vector3 = sala.ball.global_position - sala.camera.global_position
	hacia.y = 0
	hacia = hacia.normalized()
	sala.impact_point_global = sala.ball.global_position - hacia * sala.ball_radius
	sala.setup_cue_stick()
	comprobar(is_equal_approx(sala.taco.global_position.distance_to(sala.impact_point_global), sala.cue_initial_distance), "Taco comienza junto a blanca")
	var retroceso := InputEventMouseMotion.new()
	retroceso.relative.y = 1000
	sala._input(retroceso)
	sala._input(retroceso)
	var distancia: float = (sala.impact_point_global - sala.taco.global_position).dot(hacia)
	comprobar(distancia <= sala.cue_initial_distance + sala.cue_max_pullback + 0.001, "Retroceso acotado incluso con movimientos grandes")
	comprobar(distancia > sala.cue_initial_distance + 0.65, "Taco permite más retroceso que antes")
	comprobar(not sala.partida.reglas.en_tiro, "Retirar taco no golpea")
	var avance := InputEventMouseMotion.new()
	avance.relative.y = -10
	for i in range(15):
		sala._input(avance)
		if sala.partida.reglas.en_tiro:
			break
	comprobar(sala.partida.reglas.en_tiro and sala.is_waiting_for_ball, "El taco puede golpear desde el retroceso máximo")
	print("TACO VISTA TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)

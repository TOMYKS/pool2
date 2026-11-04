extends SceneTree
func _initialize() -> void:
	probar.call_deferred()
func probar() -> void:
	var args := OS.get_cmdline_user_args()
	var roce := float(args[0]) if args.size() > 0 else 0.6
	var fuerza := float(args[1]) if args.size() > 1 else 28.0
	var eje := args[2] if args.size() > 2 else "x"
	var sala = load("res://scenes/sala.tscn").instantiate()
	var bola: RigidBody3D = sala.get_node("Ball0")
	bola.get_parent().remove_child(bola)
	sala.free()
	var mesa = load("res://scenes/mesa.tscn").instantiate()
	root.add_child(mesa)
	if args.size() > 4 and args[4] == "pano":
		var pano: PhysicsMaterial = mesa.get_node("Pano").physics_material_override.duplicate()
		pano.friction = 0.2
		pano.rough = true
		mesa.get_node("Pano").physics_material_override = pano
	bola.position = Vector3(1.5 if eje == "z" else 0.0, 4.3161234, 0)
	bola.roce_velocidad = roce
	if args.size() > 3:
		bola.desaceleracion_rodadura = float(args[3])
	bola.contact_monitor = true
	bola.max_contacts_reported = 16
	root.add_child(bola)
	await process_frame
	for i in range(20):
		await physics_frame
	var direccion := Vector3.BACK if eje == "z" else Vector3.RIGHT
	bola.apply_central_impulse(direccion * fuerza)
	var anterior := bola.position
	var distancia := 0.0
	var reposo := 0.0
	var rebotes := 0
	var sentido := 1.0
	for i in range(Engine.physics_ticks_per_second * 25):
		await physics_frame
		distancia += bola.position.distance_to(anterior)
		anterior = bola.position
		var avance := bola.linear_velocity.dot(direccion)
		if absf(avance) > 0.1 and signf(avance) != sentido:
			rebotes += 1
			sentido = signf(avance)
		if bola.sleeping:
			reposo = float(i) / Engine.physics_ticks_per_second
			break
	print(JSON.stringify({"roce":roce,"fuerza":fuerza,"eje":eje,"distancia":distancia,"largos_mesa":distancia / 9.81,"rebotes":rebotes,"reposo_s":reposo}))
	bola.free()
	mesa.free()
	var correcto := reposo > 0.0
	if roce >= 0.6 and fuerza == 28.0:
		correcto = correcto and distancia < 3.0 * 9.81
	if fuerza <= 0.5:
		correcto = correcto and distancia > 0.03
	quit(0 if correcto else 1)

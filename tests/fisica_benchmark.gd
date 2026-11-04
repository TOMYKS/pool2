extends SceneTree

func _initialize() -> void:
	probar.call_deferred()

func probar() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 10:
		Engine.physics_ticks_per_second = int(args[10])
	var perfil := args[0] if args.size() > 0 else "actual"
	var angulo := float(args[1]) if args.size() > 1 else 0.0
	var fuerza := float(args[2]) if args.size() > 2 else 28.0
	var sala = load("res://scenes/sala.tscn").instantiate()
	var limite: float = sala.velocidad_vertical_maxima_color
	var mesa = load("res://scenes/mesa.tscn").instantiate()
	var bolas: Array[RigidBody3D] = [sala.get_node("Ball0")]
	for bola in sala.get_node("Bolas").get_children():
		bolas.append(bola)
	var azar := RandomNumberGenerator.new()
	azar.seed = int(args[8]) if args.size() > 8 else 1
	var factor: float = float(args[11]) if args.size() > 11 else sala.separacion_triangulo
	preload("res://scripts/armado_triangulo.gd").preparar(bolas.slice(1), sala.variacion_triangulo, sala.angulo_triangulo, azar, factor)
	for bola in bolas:
		if args.size() > 5:
			bola.mass = float(args[5])
		if args.size() > 6:
			bola.linear_damp = float(args[6])
		bola.get_parent().remove_child(bola)
	sala.free()
	# Referencia reproducible de los materiales previos a este ajuste.
	if perfil == "anterior":
		Engine.physics_ticks_per_second = 60
		for i in range(bolas.size()):
			var bola := bolas[i]
			bola.mass = 1.0 if i == 0 else 0.8
			bola.linear_damp = 0.5 if i == 0 else 0.0
			bola.angular_damp = 1.0 if i == 0 else 2.0
			bola.desaceleracion_rodadura = 0.0
			bola.roce_velocidad = 0.0
			var material := PhysicsMaterial.new()
			material.friction = 0.1 if i == 0 else 0.4
			material.bounce = 0.8 if i == 0 else 0.9
			bola.physics_material_override = material
		var pano := PhysicsMaterial.new()
		pano.friction = 1.0
		pano.bounce = 0.5
		pano.absorbent = true
		mesa.get_node("Pano").physics_material_override = pano
		var banda := PhysicsMaterial.new()
		banda.friction = 0.0
		banda.bounce = 0.2
		banda.absorbent = true
		mesa.get_node("Bordes").physics_material_override = banda
	root.add_child(mesa)
	if args.size() > 4:
		var rebote := float(args[4])
		for bola in bolas:
			bola.physics_material_override = bola.physics_material_override.duplicate()
			bola.physics_material_override.bounce = rebote
	if args.size() > 9:
		mesa.get_node("Bordes").physics_material_override = mesa.get_node("Bordes").physics_material_override.duplicate()
		mesa.get_node("Bordes").physics_material_override.bounce = float(args[9])
	for bola in bolas:
		bola.velocidad_vertical_maxima = limite
		if args.size() > 7:
			bola.roce_velocidad = float(args[7])
		if args.size() > 3:
			bola.desaceleracion_rodadura = float(args[3])
		root.add_child(bola)
	await process_frame
	for i in range(30):
		await physics_frame
	bolas[0].sleeping = false
	bolas[0].apply_central_impulse(Vector3.LEFT.rotated(Vector3.UP, angulo) * fuerza)
	var energia_max := 0.0
	var velocidad_maxima_color := 0.0
	var distancia_total := 0.0
	var posiciones := {}
	for bola in bolas:
		posiciones[bola.name] = bola.position
	var energia_inicial := fuerza * fuerza / (2.0 * bolas[0].mass)
	var salidas := {}
	var asentado := 0.0
	for i in range(Engine.physics_ticks_per_second * 30):
		await physics_frame
		var energia := 0.0
		var quietas := true
		for bola in bolas:
			if not bola.freeze:
				distancia_total += bola.position.distance_to(posiciones[bola.name])
				posiciones[bola.name] = bola.position
				if bola != bolas[0]:
					velocidad_maxima_color = maxf(velocidad_maxima_color, bola.linear_velocity.length())
			var radio: float = bola.get_node("CollisionShape3D").shape.radius
			if (absf(bola.position.x) > 4.92 or absf(bola.position.z) > 2.44) and bola.position.y - radio > 4.43:
				salidas[bola.name] = true
			if not bola.freeze and bola.position.y < 3.5:
				bola.freeze = true
			if not bola.freeze:
				energia += bola.mass * bola.linear_velocity.length_squared() * 0.5
				if bola.linear_velocity.length() > 0.06:
					quietas = false
		energia_max = maxf(energia_max, energia)
		if quietas and i > Engine.physics_ticks_per_second and asentado == 0.0:
			asentado = float(i) / Engine.physics_ticks_per_second
	var fondo := 0
	var opuesta := 0
	var caidas := 0
	var zonas := {}
	var max_vecinos := 0
	for bola in bolas.slice(1):
		if bola.freeze:
			caidas += 1
			continue
		fondo += int(bola.position.x < -3.8)
		opuesta += int(bola.position.x > 0)
		zonas[Vector2i(clampi(int((bola.position.x + 4.9) / 3.27), 0, 2), clampi(int((bola.position.z + 2.4) / 1.6), 0, 2))] = true
		var vecinos := 0
		for otra in bolas.slice(1):
			if otra != bola and not otra.freeze and otra.position.distance_to(bola.position) < 0.7:
				vecinos += 1
		max_vecinos = maxi(max_vecinos, vecinos)
	print(JSON.stringify({"args":args,"perfil":perfil, "angulo":angulo,"fuerza":fuerza,"fondo":fondo,"opuesta":opuesta,"caidas":caidas,"zonas":zonas.size(),"vecinos":max_vecinos,"reposo_s":asentado,"energia_max":energia_max,"salidas":salidas.size(),"velocidad_maxima_color":velocidad_maxima_color,"distancia_total":distancia_total}))
	for bola in bolas:
		bola.free()
	mesa.free()
	if perfil in ["actual", "apertura"] and (asentado == 0.0 or energia_max > energia_inicial * 1.02 or not salidas.is_empty()):
		push_error("La física debe disipar energía, alcanzar el reposo y mantener las bolas bajo las bandas")
		quit(1)
		return
	if perfil == "apertura" and (fondo > 4 or (absf(angulo) < 0.0001 and zonas.size() < 4)):
		push_error("El saque no debe volver a concentrarse en la banda del fondo")
		quit(1)
		return
	quit()

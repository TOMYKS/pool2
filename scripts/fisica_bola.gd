extends RefCounted

# Esfera maciza: I = 2/5 m R². Unidades del proyecto.
const PERFIL = preload("res://physics/billar.tres")

static func radio_de(bola: RigidBody3D) -> float:
	var colision := bola.get_node("CollisionShape3D") as CollisionShape3D
	return (colision.shape as SphereShape3D).radius * absf(colision.global_basis.get_scale().x)

static func preparar(bola: RigidBody3D) -> void:
	bola.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	bola.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	bola.linear_damp = 0.0
	bola.angular_damp = 0.0
	bola.set("desaceleracion_rodadura", PERFIL.friccion_rodadura * gravedad())
	bola.add_to_group("bolas_fisica")
	bola.max_contacts_reported = maxi(bola.max_contacts_reported, 16)
	bola.can_sleep = false # El reposo propio conserva draw/follow lentos.
	bola.gravity_scale = PERFIL.unidades_por_metro
	var material := PhysicsMaterial.new()
	material.bounce = PERFIL.restitucion_bolas * 0.5
	material.friction = PERFIL.friccion_bolas_lenta
	bola.physics_material_override = material
	bola.set_meta("material_billar", material)

# Impulso limitado al punto de rodadura: no invierte el deslizamiento.
static func paso(v: Vector3, w: Vector3, radio: float, dt: float, rodadura: float, roce: float) -> Array[Vector3]:
	if radio <= 0.0 or dt <= 0.0:
		return [v, w]
	var brazo := Vector3.DOWN * radio
	var slip := v + w.cross(brazo)
	slip.y = 0.0
	var restante := dt
	if slip.length() > 0.000001 and PERFIL.friccion_deslizamiento > 0.0:
		var tiempo_slip := slip.length() / (3.5 * PERFIL.friccion_deslizamiento * gravedad())
		var usado := minf(dt, tiempo_slip)
		var dv := -slip.normalized() * PERFIL.friccion_deslizamiento * gravedad() * usado
		v += dv
		w += brazo.cross(dv) * (2.5 / (radio * radio))
		restante -= usado
	var residual := v + w.cross(brazo)
	residual.y = 0.0
	if restante > 0.0 and residual.length_squared() < 0.000001:
		var plano := Vector3(v.x, 0.0, v.z)
		plano = plano.move_toward(Vector3.ZERO, (maxf(0.0, rodadura) + maxf(0.0, roce) * maxf(0.0, plano.length() - 2.0 * PERFIL.unidades_por_metro)) * restante)
		v.x = plano.x
		v.z = plano.z
		var giro := Vector3.UP.cross(plano) / radio
		w.x = giro.x
		w.z = giro.z
	w.y = move_toward(w.y, 0.0, PERFIL.friccion_giro * gravedad() / radio * dt)
	return [v, w]

static func integrar(state: PhysicsDirectBodyState3D, ascenso: float, rodadura: float, roce_velocidad: float = 0.0, radio: float = 0.14, factor_comba: float = 0.0) -> void:
	var v := state.linear_velocity
	if ascenso > 0.0:
		v.y = minf(v.y, ascenso)
	for i in range(state.get_contact_count()):
		var cuerpo := state.get_contact_collider_object(i)
		if cuerpo is StaticBody3D and cuerpo.name == "Pano" and state.get_contact_local_normal(i).y > 0.9:
			var resultado := paso(v, state.angular_velocity, radio, state.step, rodadura, roce_velocidad)
			v = resultado[0]
			var giro := resultado[1]
			if factor_comba > 0.0:
				# Girar ambos vectores en el paño conserva rapidez y deslizamiento relativo.
				var velocidad_angular := clampf(giro.y * PERFIL.intensidad_comba, -2.2, 2.2)
				var angulo := velocidad_angular * state.step * factor_comba
				v = v.rotated(Vector3.UP, angulo)
				giro = giro.rotated(Vector3.UP, angulo)
			state.angular_velocity = giro
			break
	state.linear_velocity = v

static func gravedad() -> float:
	return 9.8 * PERFIL.unidades_por_metro

# El centro visual de la blanca significa contacto central. Proyectar el clic
# en su plano de vista evita que la altura de la camara agregue topspin.
static func seleccionar_impacto(origen: Vector3, rayo: Vector3, centro: Vector3, radio: float) -> Dictionary:
	var vista := (centro - origen).normalized()
	var direccion := Vector3(vista.x, 0.0, vista.z).normalized()
	var denominador := rayo.dot(vista)
	if radio <= 0.0 or direccion.is_zero_approx() or denominador <= 0.000001:
		return {}
	var derecha := direccion.cross(Vector3.UP).normalized()
	var arriba_vista := derecha.cross(vista).normalized()
	var plano := origen + rayo * (centro - origen).dot(vista) / denominador - centro
	var efecto := Vector2(plano.dot(derecha), plano.dot(arriba_vista)).limit_length(radio * PERFIL.limite_efecto)
	var transversal := derecha * efecto.x + Vector3.UP * efecto.y
	var frontal := sqrt(maxf(0.0, radio * radio - transversal.length_squared()))
	return {"punto": centro + transversal - direccion * frontal, "direccion": direccion, "efecto": efecto / radio}

# Contacto de taco de masa finita; conserva el impulso central de los controles.
# No copia codigo propietario: impulso rigido y momento r × J de esfera maciza.
static func calcular_golpe(direccion: Vector3, offset: Vector3, radio: float, potencia: float) -> Dictionary:
	var eje := direccion.normalized()
	if radio <= 0.0 or eje.is_zero_approx() or potencia <= 0.0:
		return {"impulso": Vector3.ZERO, "brazo": Vector3.ZERO}
	var transversal := offset - eje * offset.dot(eje)
	transversal = transversal.limit_length(radio * PERFIL.limite_efecto)
	var masa_efectiva: float = 1.0 + 1.0 / PERFIL.masa_relativa_taco
	var eficiencia: float = masa_efectiva / (masa_efectiva + 2.5 * transversal.length_squared() / (radio * radio))
	var lateral := eje.cross(Vector3.UP).normalized()
	var efecto_lateral := transversal.dot(lateral) / radio
	# Desviacion al salir del taco hacia el lado opuesto al contacto.
	var desvio := deg_to_rad(PERFIL.desvio_lateral_maximo_grados * efecto_lateral / maxf(PERFIL.limite_efecto, 0.001))
	var vertical := transversal - lateral * transversal.dot(lateral)
	var brazo := transversal - vertical * (1.0 - PERFIL.intensidad_avance_retroceso)
	return {"impulso": eje.rotated(Vector3.UP, desvio) * potencia * eficiencia, "brazo": brazo}

# Preparar la friccion antes de entrar en contacto: cambiarla dentro de
# _integrate_forces llega tarde para el primer impulso del solver.
static func anticipar_contactos(bola: RigidBody3D, dt: float) -> void:
	var material := bola.get_meta("material_billar", null) as PhysicsMaterial
	if material == null or bola.physics_material_override != material or bola.freeze:
		return
	var mu: float = PERFIL.friccion_bolas_lenta
	var primero := INF
	var radio := radio_de(bola)
	for nodo in bola.get_tree().get_nodes_in_group("bolas_fisica"):
		var otra := nodo as RigidBody3D
		if otra == bola or otra.freeze or bola.get_collision_exceptions().has(otra):
			continue
		var dp := otra.global_position - bola.global_position
		var dv := otra.linear_velocity - bola.linear_velocity
		var velocidad2 := dv.length_squared()
		if velocidad2 < 0.00000001:
			continue
		var suma_radios := radio + radio_de(otra) + 0.002
		var c := dp.length_squared() - suma_radios * suma_radios
		var b := dp.dot(dv)
		if b >= 0.0:
			continue
		var discriminante := b*b - velocidad2*c
		if discriminante < 0.0:
			continue
		var t := maxf(0.0, (-b - sqrt(discriminante)) / velocidad2)
		if t > dt * 2.0 or t >= primero:
			continue
		primero = t
		var normal := (dp + dv * t).normalized()
		var relativa := bola.linear_velocity - otra.linear_velocity + bola.angular_velocity.cross(normal * radio) + otra.angular_velocity.cross(normal * radio_de(otra))
		var tangente := relativa - normal * relativa.dot(normal)
		mu = PERFIL.friccion_contacto(tangente.length() / PERFIL.unidades_por_metro)
	material.friction = mu

static func actualizar_contactos(bola: RigidBody3D, state: PhysicsDirectBodyState3D) -> void:
	var material := bola.get_meta("material_billar", null) as PhysicsMaterial
	if material == null or bola.physics_material_override != material:
		return # Respetar materiales especiales de los poderes.
	var rapidez := state.linear_velocity.length() / PERFIL.unidades_por_metro
	var radio := radio_de(bola)
	for i in range(state.get_contact_count()):
		var otra := state.get_contact_collider_object(i) as RigidBody3D
		if otra == null or not otra.has_meta("material_billar"):
			continue
		var normal := (bola.global_position - otra.global_position).normalized()
		var propia := state.linear_velocity + state.angular_velocity.cross(-normal * radio)
		var ajena := otra.linear_velocity + otra.angular_velocity.cross(normal * radio_de(otra))
		var relativa := propia - ajena
		var tangente := relativa - normal * relativa.dot(normal)
		rapidez = tangente.length() / PERFIL.unidades_por_metro
		break
	material.friction = PERFIL.friccion_contacto(rapidez)

# El poder conserva más velocidad en banda y sale rodando sobre el paño.
static func aplicar_rebote_extra_banda(state: PhysicsDirectBodyState3D, entrada: Vector3, radio: float) -> void:
	entrada.y = 0.0
	for i in range(state.get_contact_count()):
		var cuerpo := state.get_contact_collider_object(i)
		if not cuerpo is StaticBody3D or cuerpo.name != "Bordes":
			continue
		var normal := state.get_contact_local_normal(i)
		normal.y = 0.0
		normal = normal.normalized()
		var rapidez_entrada := -entrada.dot(normal)
		var salida := state.linear_velocity
		if rapidez_entrada < 0.05 or salida.dot(normal) <= 0.0:
			continue
		var vertical := minf(0.0, salida.y)
		salida.y = 0.0
		var rapidez_salida := maxf(salida.dot(normal), rapidez_entrada * 0.94)
		salida = (salida.slide(normal) + normal * rapidez_salida).limit_length(entrada.length())
		var giro := Vector3.UP.cross(salida) / radio
		giro.y = state.angular_velocity.y
		state.angular_velocity = giro
		salida.y = vertical
		state.linear_velocity = salida
		return


static func preparar_mesa(mesa: Node3D) -> void:
	var pano := mesa.get_node("Pano") as StaticBody3D
	var tapete := PhysicsMaterial.new()
	tapete.friction = 0.0 # El paño usa exclusivamente paso().
	tapete.bounce = 1.0
	tapete.absorbent = true
	pano.physics_material_override = tapete
	var banda := PhysicsMaterial.new()
	banda.friction = PERFIL.friccion_banda
	banda.rough = true
	# Godot suma restituciones cuando ninguno de los cuerpos es absorbente.
	banda.bounce = maxf(0.0, PERFIL.restitucion_bandas - PERFIL.restitucion_bolas * 0.5)
	mesa.get_node("Bordes").physics_material_override = banda

extends Node

signal bola_retirada(bola: RigidBody3D, tronera: bool, jugador: int)

const Reglas = preload("res://scripts/reglas_pool.gd")
const ALTURA_PANO := 4.1761234
var reglas = Reglas.new()
var bola_en_mano := false
var terminada := false
var reiniciando := false
var configurando := true
var jugador_2_cpu := false
var con_powerups := false
var nombres := ["Jugador 1", "Jugador 2"]
@onready var cpu: Node = $CPU
var configuracion: Control
var _retiradas: Dictionary = {}
var _salidas: Dictionary = {}
var _mensaje := "Jugador 1 realiza el saque. Mesa abierta."
var _clic_pendiente = null
@onready var sala = get_parent()
@onready var texto: Label = $HUD/Panel/Margen/Contenido/Estado
@onready var detalle: Label = $HUD/Panel/Margen/Contenido/Detalle
@onready var reiniciar: Button = $HUD/Panel/Margen/Contenido/Reiniciar
@onready var guia: MeshInstance3D = $Guia
@onready var sonido_win = $SonidoWin
@onready var sonido_falta = $SonidoFalta

func _ready() -> void:
	sala.tiro_iniciado.connect(_iniciar_tiro)
	reiniciar.pressed.connect(reiniciar_partida)
	sala.ball.contact_monitor = true
	sala.ball.max_contacts_reported = 16
	sala.ball.set_meta("puede_recoger", false)
	sala.ball.body_entered.connect(_contacto.bind(sala.ball))
	for bola in get_tree().get_nodes_in_group("bolas_color"):
		var numero := int(str(bola.name).trim_prefix("Ball"))
		for hijo in bola.get_children():
			if hijo is MeshInstance3D and hijo.mesh != null:
				var archivo: String = hijo.mesh.resource_path.get_file().get_basename()
				if archivo.begins_with("Ball"):
					numero = int(archivo.trim_prefix("Ball"))
					break
		bola.set_meta("numero", numero)
		bola.contact_monitor = true
		bola.max_contacts_reported = 16
		bola.body_entered.connect(_contacto.bind(bola))
	_actualizar_hud()
	configuracion = preload("res://scripts/configurar_partida.gd").new()
	$HUD.add_child(configuracion)
	_control_camara(false)


func comenzar_partida(usar_cpu: bool) -> void:
	if not configurando:
		return
	jugador_2_cpu = usar_cpu
	configurando = false
	configuracion.hide()
	_control_camara(true)
	_actualizar_hud()


func es_turno_cpu() -> bool:
	return jugador_2_cpu and reglas.turno == 2


func permite_input_humano() -> bool:
	return not configurando and not terminada and not reiniciando and not es_turno_cpu()


func puede_apuntar() -> bool:
	return not configurando and not bola_en_mano and not terminada and not reiniciando and not reglas.en_tiro


func _iniciar_tiro() -> void:
	if configurando or terminada or bola_en_mano or reiniciando:
		return
	reglas.iniciar_tiro()
	# Un contacto que ya existía al empezar no emite otro body_entered.
	for cuerpo in sala.ball.get_colliding_bodies():
		if cuerpo.is_in_group("bolas_color"):
			var hacia: Vector3 = cuerpo.global_position - sala.ball.global_position
			if sala.ball.linear_velocity.dot(hacia) > 0.0:
				reglas.contacto(int(cuerpo.get_meta("numero", 0)), bool(cuerpo.get_meta("ocho_mortal", false)))
				break
	_retiradas.clear()
	_salidas.clear()
	sala.ball.set_meta("puede_recoger", true)
	_mensaje = "Tiro en curso…"
	_actualizar_hud()


func _contacto(otro: Node, bola: RigidBody3D) -> void:
	if not reglas.en_tiro:
		return
	if bola == sala.ball and otro.is_in_group("bolas_color"):
		reglas.contacto(int(otro.get_meta("numero", 0)), bool(otro.get_meta("ocho_mortal", false)))
	# También observamos el contacto desde la otra bola, por orden de señales.
	elif otro == sala.ball and bola.is_in_group("bolas_color"):
		reglas.contacto(int(bola.get_meta("numero", 0)), bool(bola.get_meta("ocho_mortal", false)))
	if otro == sala.get_node("Mesa/Bordes") or otro == sala.get_node("Mesa/Pockets") or otro.name == "Barrera" or otro.is_in_group("bandas_powerup"):
		reglas.banda(int(bola.get_meta("numero", 0)))


func _physics_process(_delta: float) -> void:
	if bola_en_mano and not es_turno_cpu():
		_actualizar_guia()
		if _clic_pendiente != null:
			var clic: Vector2 = _clic_pendiente
			_clic_pendiente = null
			var punto = punto_desde_pantalla(clic)
			if punto != null:
				colocar_blanca(punto)
			else:
				_mensaje = "Elegí un lugar libre sobre el paño."
				_actualizar_hud()
	if not reglas.en_tiro:
		return
	var bolas := get_tree().get_nodes_in_group("bolas_color")
	bolas.append(sala.ball)
	for bola in bolas:
		if bola.is_queued_for_deletion() or _retiradas.has(bola.get_instance_id()):
			continue
		var p: Vector3 = sala.to_local(bola.global_position)
		var radio := _radio(bola)
		if (absf(p.x) > 4.92 or absf(p.z) > 2.44) and p.y - radio > 4.43:
			_salidas[bola.get_instance_id()] = true
		if absf(p.x) > 6.1 or absf(p.z) > 3.8 or p.y < 3.55:
			registrar_caida(bola)


func _radio(bola: RigidBody3D) -> float:
	for hijo in bola.get_children():
		if hijo is CollisionShape3D and hijo.shape is SphereShape3D:
			return hijo.shape.radius
	return 0.14


func _es_tronera(posicion: Vector3) -> bool:
	# Huecos de las seis troneras de mesa.tscn, bajo la superficie.
	if posicion.y >= ALTURA_PANO:
		return false
	var x := absf(posicion.x)
	var z := absf(posicion.z)
	return (x > 4.25 and x < 5.85 and z > 1.95 and z < 3.6) or (x < 0.48 and z > 2.4 and z < 3.6)


func registrar_caida(body: Node3D) -> void:
	if not reglas.en_tiro or not (body is RigidBody3D):
		return
	if not body.is_in_group("bolas_color") and body != sala.ball:
		return
	var id := body.get_instance_id()
	if _retiradas.has(id):
		return
	_retiradas[id] = true
	var tronera := not _salidas.has(id) and _es_tronera(sala.to_local(body.global_position))
	var numero := int(body.get_meta("numero", 0))
	reglas.retirar(numero, tronera, bool(body.get_meta("ocho_mortal", false)))
	bola_retirada.emit(body, tronera, reglas.turno)
	if tronera:
		sala.sonido_pocket.play()
	if body == sala.ball:
		body.set_meta("puede_recoger", false)
		_ocultar_blanca.call_deferred()
	else:
		body.queue_free()
	_actualizar_hud()


func _ocultar_blanca() -> void:
	sala.ball.linear_velocity = Vector3.ZERO
	sala.ball.angular_velocity = Vector3.ZERO
	sala.ball.freeze = true
	sala.ball.hide()
	sala.ball.get_node("CollisionShape3D").disabled = true


func finalizar_tiro() -> void:
	sala.ball.set_meta("puede_recoger", false)
	var resultado: Dictionary = reglas.finalizar_tiro()
	var jugador_que_tiro = reglas.turno
	if resultado.is_empty():
		return
	_mensaje = resultado["mensaje"]
	if resultado.get("reiniciar", false):
		reiniciando = true
		_actualizar_hud()
		reiniciar_partida.call_deferred()
		return
	if resultado.has("ganador"):
		terminada = true
		if resultado["ganador"] == jugador_que_tiro:
			sonido_win.play()
		else:
			sonido_falta.volume_db = -20.0
			sonido_falta.play()
		sala.cambiar_camara(sala.camera_mesa)
		_control_camara(false)
		var poderes = sala.get_node_or_null("Powerups")
		if poderes != null and poderes.habilitado:
			poderes.alternar_sistema()
	elif resultado.get("bola_en_mano", false):
		bola_en_mano = true
		_ocultar_blanca()
		sala.cambiar_camara(sala.camera_mesa)
		_control_camara(false)
		sonido_falta.volume_db = -25.0
		sonido_falta.play()
	else:
		_camara_del_turno()
	_actualizar_hud()


func _camara_del_turno() -> void:
	if es_turno_cpu():
		sala.cambiar_camara(sala.camera_mesa)
	else:
		sala.cambiar_camara(sala.camera)
	_control_camara(true)


func _control_camara(permitir: bool) -> void:
	permitir = permitir and permite_input_humano()
	var pivote = sala.get_node("Pivot")
	pivote.set_process(permitir)
	pivote.set_process_unhandled_input(permitir)
	pivote.is_dragging_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func solicitar_colocacion(pantalla: Vector2) -> void:
	if bola_en_mano and permite_input_humano() and not sala.camara_en_transicion():
		_clic_pendiente = pantalla


func punto_desde_pantalla(pantalla: Vector2) -> Variant:
	var camara: Camera3D = sala.camera_mesa
	var plano := Plane(Vector3.UP, sala.to_global(Vector3(0, ALTURA_PANO + sala.ball_radius + 0.01, 0)).y)
	return plano.intersects_ray(camara.project_ray_origin(pantalla), camara.project_ray_normal(pantalla))


func posicion_valida(punto: Vector3) -> bool:
	var local: Vector3 = sala.to_local(punto)
	var radio: float = sala.ball_radius
	if absf(local.y - (ALTURA_PANO + radio + 0.01)) > 0.03:
		return false
	# Usar el paño real como apoyo; las bandas se comprueban con la esfera.
	var rayo := PhysicsRayQueryParameters3D.create(
		punto, punto + Vector3.DOWN * (radio + 0.03), 1,
		[sala.ball.get_rid(), sala.taco.get_rid()]
	)
	var apoyo: Dictionary = sala.get_world_3d().direct_space_state.intersect_ray(rayo)
	if apoyo.is_empty() or apoyo.collider != sala.get_node("Mesa/Pano") or apoyo.normal.y < 0.9:
		return false
	var consulta := PhysicsShapeQueryParameters3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = radio
	consulta.shape = esfera
	consulta.transform = Transform3D(Basis.IDENTITY, punto)
	consulta.collision_mask = 3
	consulta.exclude = [sala.ball.get_rid(), sala.taco.get_rid()]
	consulta.margin = 0.001
	return sala.get_world_3d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func colocar_blanca(punto: Vector3) -> bool:
	if not bola_en_mano or not posicion_valida(punto):
		_mensaje = "Ese lugar está ocupado o fuera del paño. Elegí otro."
		_actualizar_hud()
		return false
	sala.ball.global_position = punto
	sala.ball.linear_velocity = Vector3.ZERO
	sala.ball.angular_velocity = Vector3.ZERO
	sala.ball.get_node("CollisionShape3D").disabled = false
	sala.ball.show()
	sala.ball.freeze = false
	sala.ball.sleeping = false
	bola_en_mano = false
	guia.hide()
	_camara_del_turno()
	_mensaje = "Blanca colocada. Podés apuntar y tirar."
	_actualizar_hud()
	return true


func _actualizar_guia() -> void:
	var punto = punto_desde_pantalla(sala.get_viewport().get_mouse_position())
	guia.visible = punto != null
	if punto == null:
		return
	guia.global_position = punto
	guia.material_override.albedo_color = Color(0.25, 1, 0.55, 0.45) if posicion_valida(punto) else Color(1, 0.2, 0.2, 0.45)


func _actualizar_hud() -> void:
	var lineas: Array[String] = []
	lineas.append("Ganó el jugador %d" % reglas.ganador if terminada else "Turno: jugador %d%s" % [reglas.turno, " · SAQUE" if reglas.saque else ""])
	for jugador in [1, 2]:
		var grupo: int = reglas.grupos[jugador - 1]
		var nombre := "Sin asignar" if grupo == Reglas.Grupo.SIN_ASIGNAR else ("Lisas (1–7)" if grupo == Reglas.Grupo.LISAS else "Rayadas (9–15)")
		var objetivo := ""
		if grupo != Reglas.Grupo.SIN_ASIGNAR:
			var pendientes: Array[int] = reglas.pendientes(jugador)
			objetivo = " · Va por la 8" if pendientes.is_empty() else " · Quedan %d" % pendientes.size()
		lineas.append("J%d · %s%s" % [jugador, nombre, objetivo])
	texto.text = "\n".join(lineas)
	if jugador_2_cpu:
		texto.text = texto.text.replace("jugador 2", "CPU").replace("J2 ·", "CPU ·")
	detalle.text = _mensaje + ("\nBOLA EN MANO: clic en un lugar libre para colocar la blanca." if bola_en_mano else "")
	if configurando:
		detalle.text = "Elegí el jugador 2 para comenzar."
	elif es_turno_cpu() and not terminada:
		detalle.text = "CPU jugando…" if reglas.en_tiro else "CPU pensando…"
	reiniciar.visible = terminada
	# Refrescar las dos filas al asignar grupos o registrar cualquier caída.
	get_node("HUD/Panel").actualizar()


func reiniciar_partida() -> void:
	get_tree().reload_current_scene()

func nombre_jugador(jugador: int) -> String:
	return "CPU" if jugador == 2 and jugador_2_cpu else nombres[jugador - 1]

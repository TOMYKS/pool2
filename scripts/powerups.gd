extends Node3D

@export_range(0.0, 1.0, 0.05) var probabilidad_aparicion := 0.85
var _ultimo_poder: int = -1

const ACTIVADOR = preload("res://scenes/activador.tscn")
enum TipoPoder { PESADAS, REBOTE, GRANDES, PARED, INVISIBLES, FANTASMAS }
const PODERES := {
	TipoPoder.PESADAS: {"activar": "activar_bolas_pesadas", "desactivar": "desactivar_bolas_pesadas", "nombre": "Bolas pesadas", "escena": "pesadas", "duracion": "tiros_pesadas"},
	TipoPoder.REBOTE: {"activar": "activar_bolas_rebotonas", "desactivar": "desactivar_bolas_rebotonas", "nombre": "Rebote extra", "escena": "rebote", "duracion": "tiros_rebote"},
	TipoPoder.GRANDES: {"activar": "activar_bolas_grandes", "desactivar": "desactivar_bolas_grandes", "nombre": "Bolas grandes", "escena": "grandes", "duracion": "tiros_grandes"},
	TipoPoder.PARED: {"activar": "activar_pared", "desactivar": "desactivar_pared", "nombre": "Pared", "escena": "pared", "duracion": "tiros_pared"},
	TipoPoder.INVISIBLES: {"activar": "activar_bolas_invisibles", "desactivar": "desactivar_bolas_invisibles", "nombre": "Bolas invisibles", "escena": "invisibles", "duracion": ""},
	TipoPoder.FANTASMAS: {"activar": "activar_bolas_fantasmas", "desactivar": "desactivar_bolas_fantasmas", "nombre": "Bolas falsas", "escena": "fantasmas", "duracion": "tiros_fantasmas"},
}

var habilitado := false
var poder_actual: int = -1
var tiros_restantes := 0
var activador: Area3D
var _controladores: Dictionary = {}
var _originales: Array[Dictionary] = []
var _azar := RandomNumberGenerator.new()
var _tiro := 0
var _tiro_recogida := -1
var _ultimo_tiro_preparado := -1
var _posicion_anterior := Vector3.ZERO
var _listo := false
@onready var _sala = get_parent()
@onready var _estado: Label = $HUD/Estado
@onready var sonido_poder = $Powerup

func _ready() -> void:
	_azar.randomize()
	_preparar.call_deferred()


func _preparar() -> void:
	# Reutilizamos los poderes ya presentes. Los demás se crean como hijos
	# de Sala porque sus coordenadas y referencias están definidas allí.
	for clave in PODERES:
		var controlador: Node
		for hijo in _sala.get_children():
			if hijo.has_method(PODERES[clave]["activar"]):
				controlador = hijo
				break
		if controlador == null:
			controlador = load("res://scenes/%s.tscn" % PODERES[clave]["escena"]).instantiate()
			_sala.add_child(controlador)
		controlador.set_process_input(false)
		_controladores[clave] = controlador
	_sala.tiro_iniciado.connect(_al_iniciar_tiro)
	_sala.tiro_finalizado.connect(_al_finalizar_tiro)
	_posicion_anterior = _sala.ball.global_position
	_listo = true


func _input(event: InputEvent) -> void:
	var partida = _sala.get_node_or_null("Partida")
	if partida != null and (partida.terminada or partida.reiniciando):
		return
	if _listo and event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		alternar_sistema.call_deferred()


func alternar_sistema() -> void:
	habilitado = not habilitado
	if habilitado:
		_posicion_anterior = _sala.ball.global_position
		_intentar_aparicion(true)
	else:
		_quitar_activador()
		_terminar_poder()
	_actualizar_estado()


func _physics_process(_delta: float) -> void:
	if not _listo:
		return
	var posicion: Vector3 = _sala.ball.global_position
	if habilitado and is_instance_valid(activador):
		# Ignoramos teletransportes (por ejemplo, reposición de la blanca).
		if posicion.distance_to(_posicion_anterior) <= 1.0:
			activador.comprobar_recorrido(_sala.ball, _posicion_anterior, posicion)
	_posicion_anterior = posicion


func _al_iniciar_tiro() -> void:
	_tiro += 1


func _al_finalizar_tiro() -> void:
	var partida = _sala.get_node_or_null("Partida")
	if partida != null and (partida.terminada or partida.reiniciando):
		return
	if not habilitado:
		return
	# Normalmente main prepara el vencimiento antes de resolver las reglas.
	# Es idempotente para no descontar otra vez al emitir tiro_finalizado.
	preparar_fin_tiro()
	_intentar_aparicion()
	_actualizar_estado()


func preparar_fin_tiro() -> bool:
	if _ultimo_tiro_preparado == _tiro:
		return false
	_ultimo_tiro_preparado = _tiro
	if not habilitado:
		return false
	var cambio_fisico := false
	if poder_actual != -1 and _tiro > _tiro_recogida:
		tiros_restantes -= 1
		if tiros_restantes <= 0:
			_terminar_poder()
			cambio_fisico = true
	_actualizar_estado()
	return cambio_fisico


func _intentar_aparicion(forzar := false) -> void:
	if not habilitado or poder_actual != -1 or is_instance_valid(activador):
		return
	if get_tree().get_nodes_in_group("bolas_color").is_empty():
		return
	if not forzar and _azar.randf() > probabilidad_aparicion:
		return
	var forma := SphereShape3D.new()
	forma.radius = 0.42
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = forma
	consulta.collision_mask = 3
	for intento in range(100):
		# Interior del paño: margen suficiente respecto de bandas y troneras.
		var punto := Vector3(_azar.randf_range(-4.1, 4.1), 4.34, _azar.randf_range(-1.65, 1.65))
		var global: Vector3 = _sala.to_global(punto)
		# Elevamos solo la consulta para no intersectar el propio paño.
		consulta.transform = Transform3D(Basis.IDENTITY, global + Vector3.UP * 0.32)
		if not get_world_3d().direct_space_state.intersect_shape(consulta, 1).is_empty():
			continue
		activador = ACTIVADOR.instantiate()
		add_child(activador)
		activador.global_position = global
		activador.recogido.connect(_solicitar_recogida)
		return


func _solicitar_recogida() -> void:
	_recoger.call_deferred()


func _recoger() -> void:
	if not _sala.ball.get_meta("puede_recoger", true):
		return
	if not habilitado or poder_actual != -1 or not is_instance_valid(activador):
		return
	_quitar_activador()
	_guardar_originales()
	# El sorteo ocurre AHORA, nunca al crear el activador.
	var opciones: Array = PODERES.keys()
	if _ultimo_poder != -1 and opciones.size() > 1:
		opciones.erase(_ultimo_poder)
	while not opciones.is_empty():
		var indice := _azar.randi_range(0, opciones.size() - 1)
		var clave: TipoPoder = opciones.pop_at(indice)
		var resultado = _controladores[clave].call(PODERES[clave]["activar"])
		if clave == TipoPoder.PARED and resultado != true:
			continue
		poder_actual = clave
		_ultimo_poder = clave
		# Sorteo del 1 al 6 para definir la duración
		var sorteo_duracion = _azar.randi_range(1, 6)
		if sorteo_duracion <= 2:
			tiros_restantes = 1 # 2/6 de probabilidad (Números 1 y 2)
		elif sorteo_duracion <= 5:
			tiros_restantes = 2 # 3/6 de probabilidad (Números 3, 4 y 5)
		else:
			tiros_restantes = 3 # 1/6 de probabilidad (Número 6)
		_tiro_recogida = _tiro
		break
	_actualizar_estado()


func _guardar_originales() -> void:
	# Los poderes viejos restauran valores fijos. Guardamos el estado real
	# y aislamos sus materiales para que muchas activaciones no lo alteren.
	_originales.clear()
	for bola in get_tree().get_nodes_in_group("bolas_color"):
		if bola.is_queued_for_deletion():
			continue
		var mallas: Array[Dictionary] = []
		for hijo in bola.get_children():
			if hijo is MeshInstance3D and hijo.get_active_material(0) != null:
				mallas.append({"nodo": hijo, "override": hijo.material_override})
				hijo.material_override = hijo.get_active_material(0).duplicate()
		_originales.append({"bola": bola, "masa": bola.mass, "fisica": bola.physics_material_override, "mallas": mallas})


func _terminar_poder() -> void:
	if poder_actual == -1:
		return
	_controladores[poder_actual].call(PODERES[poder_actual]["desactivar"])
	for datos in _originales:
		var bola = datos["bola"]
		if not is_instance_valid(bola) or bola.is_queued_for_deletion():
			continue
		bola.mass = datos["masa"]
		bola.physics_material_override = datos["fisica"]
		for malla in datos["mallas"]:
			if is_instance_valid(malla["nodo"]):
				malla["nodo"].material_override = malla["override"]
	_originales.clear()
	poder_actual = -1
	tiros_restantes = 0


func _quitar_activador() -> void:
	if is_instance_valid(activador):
		sonido_poder.play()
		activador.hide()
		activador.queue_free()
	activador = null


func _actualizar_estado() -> void:
	if not habilitado:
		_estado.text = "Power-ups apagados · Espacio para activar"
	elif poder_actual != -1:
		_estado.text = "%s · %d tiro(s) restantes · Espacio para apagar" % [PODERES[poder_actual]["nombre"], tiros_restantes]
	elif is_instance_valid(activador):
		_estado.text = "Tocá el ? con la blanca · Poder sorpresa · Espacio para apagar"
	else:
		_estado.text = "Power-ups encendidos · Esperando activador · Espacio para apagar"

extends Node3D

@export var tecla_activacion: Key = KEY_SPACE

const MALLA_OCHO = preload("res://assets/Ball8.res")
const Reglas = preload("res://scripts/reglas_pool.gd")
var powerup_ochos_activo := false
var _originales: Array[Dictionary] = []
var _azar := RandomNumberGenerator.new()
var _generacion := 0
@onready var _partida = get_parent().get_node("Partida")


func _ready() -> void:
	_azar.randomize()
	_partida.bola_retirada.connect(_al_retirar_bola)


func _input(event: InputEvent) -> void:
	if _partida.terminada or _partida.reiniciando:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == tecla_activacion:
		if powerup_ochos_activo:
			desactivar_ochos()
		else:
			activar_ochos()


func activar_ochos() -> void:
	if powerup_ochos_activo:
		return
	powerup_ochos_activo = true
	_generacion += 1
	for bola in get_tree().get_nodes_in_group("bolas_color"):
		if bola.is_queued_for_deletion():
			continue
		var visual: MeshInstance3D
		for hijo in bola.get_children():
			if hijo is MeshInstance3D:
				visual = hijo
				break
		if visual == null:
			continue
		var superficies: Array[Material] = []
		for i in range(visual.mesh.get_surface_count()):
			superficies.append(visual.get_surface_override_material(i))
		_originales.append({"bola": bola, "visual": visual, "malla": visual.mesh,
			"material": visual.material_override, "superficies": superficies,
			"grupo": _partida.reglas.grupo_de(int(bola.get_meta("numero")))})
		# Conservamos el número original para los grupos y el conteo de la partida.
		bola.set_meta("ocho_mortal", true)
		visual.mesh = MALLA_OCHO
		visual.material_override = null
		for i in range(MALLA_OCHO.get_surface_count()):
			visual.set_surface_override_material(i, null)
	_revelar(Reglas.Grupo.LISAS, _generacion)
	_revelar(Reglas.Grupo.RAYADAS, _generacion)


func _al_retirar_bola(bola: RigidBody3D, tronera: bool, jugador: int) -> void:
	if not powerup_ochos_activo or not tronera or bola.get_meta("ocho_mortal", false):
		return
	var grupo: int = _partida.reglas.grupo_de(int(bola.get_meta("numero", 0)))
	var grupo_jugador: int = _partida.reglas.grupos[jugador - 1]
	if grupo == Reglas.Grupo.SIN_ASIGNAR:
		return
	if grupo_jugador != Reglas.Grupo.SIN_ASIGNAR and grupo_jugador != grupo:
		return
	# Esperar las demás caídas del mismo paso evita salvar por orden de señales
	# a otra negra que ya estaba entrando. Tampoco se eligen nodos retirados.
	_revelar.call_deferred(grupo, _generacion)


func _revelar(grupo: int, generacion: int) -> void:
	if not powerup_ochos_activo or generacion != _generacion or _partida.reglas.ocho_mortal_embocado:
		return
	var candidatas: Array[Dictionary] = []
	for datos in _originales:
		var bola = datos["bola"]
		if not is_instance_valid(bola) or bola.is_queued_for_deletion() or datos["grupo"] != grupo:
			continue
		if not bola.get_meta("ocho_mortal", false):
			return # Nunca dejar dos bolas visibles del mismo grupo.
		if get_parent().to_local(bola.global_position).y < _partida.ALTURA_PANO:
			continue
		candidatas.append(datos)
	if candidatas.is_empty():
		return
	var elegida: Dictionary = candidatas[_azar.randi_range(0, candidatas.size() - 1)]
	_restaurar(elegida)


func _restaurar(datos: Dictionary) -> void:
	var bola = datos["bola"]
	if not is_instance_valid(bola) or bola.is_queued_for_deletion():
		return
	if bola.has_meta("ocho_mortal"):
		bola.remove_meta("ocho_mortal")
	var visual: MeshInstance3D = datos["visual"]
	visual.mesh = datos["malla"]
	visual.material_override = datos["material"]
	for i in range(datos["superficies"].size()):
		visual.set_surface_override_material(i, datos["superficies"][i])


func desactivar_ochos() -> void:
	powerup_ochos_activo = false
	_generacion += 1
	for datos in _originales:
		_restaurar(datos)
	_originales.clear()


func _exit_tree() -> void:
	desactivar_ochos()

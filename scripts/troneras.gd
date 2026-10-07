extends Node3D

enum Patron { ALEATORIO, UN_LADO, MEZCLA, TODAS }
## ALEATORIO sortea entre un lado completo, una combinación y las seis.
@export var patron: Patron = Patron.ALEATORIO
@export var tecla_activacion: Key = KEY_SPACE

const ALTURA_PANO := 4.1761234
# Orden: esquinas y centro del lado -Z; esquinas y centro del lado +Z.
const CENTROS := [Vector2(-4.7, -2.3), Vector2(0, -2.5), Vector2(4.7, -2.3),
	Vector2(-4.7, 2.3), Vector2(0, 2.5), Vector2(4.7, 2.3)]
const LADOS := [[0, 1, 2], [3, 4, 5], [0, 3], [2, 5]]
const TAMANO := Vector3(1.3, 0.5, 0.22)

var powerup_troneras_activo := false
var seleccionadas: Array[int] = []
var _tapas: Array[StaticBody3D] = []
var _pendientes: Array[int] = []
var _azar := RandomNumberGenerator.new()
var _alternar_pendiente := false


func _ready() -> void:
	_azar.randomize()
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/powerups/troneras.gdshader")
	var bordes := get_parent().get_node("Mesa/Bordes") as StaticBody3D
	for i in range(CENTROS.size()):
		var tapa := StaticBody3D.new()
		tapa.name = "Tapa%d" % (i + 1)
		tapa.add_to_group("bandas_powerup")
		tapa.physics_material_override = bordes.physics_material_override.duplicate()
		add_child(tapa)
		var centro: Vector2 = CENTROS[i]
		var angulo := 0.0 if centro.x == 0.0 else signf(centro.x * centro.y) * PI / 4.0
		tapa.global_transform = get_parent().global_transform * Transform3D(
			Basis(Vector3.UP, angulo), Vector3(centro.x, ALTURA_PANO + 0.15, centro.y))
		var forma := BoxShape3D.new()
		forma.size = TAMANO
		var colision := CollisionShape3D.new()
		colision.name = "Colision"
		colision.shape = forma
		colision.disabled = true
		tapa.add_child(colision)
		_agregar_malla(tapa, TAMANO, Vector3.ZERO, material)
		tapa.hide()
		_tapas.append(tapa)


func _agregar_malla(padre: Node3D, tamano: Vector3, centro: Vector3, material: Material) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	visual.mesh = caja
	visual.material_override = material
	visual.position = centro
	padre.add_child(visual)
	return visual


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == tecla_activacion:
		_alternar_pendiente = not _alternar_pendiente


func _physics_process(_delta: float) -> void:
	if _alternar_pendiente:
		_alternar_pendiente = false
		if powerup_troneras_activo:
			desactivar_troneras()
		else:
			activar_troneras()
	if powerup_troneras_activo:
		_cerrar_libres()


func activar_troneras() -> void:
	if powerup_troneras_activo:
		return
	powerup_troneras_activo = true
	seleccionadas = _sortear_troneras()
	_pendientes.assign(seleccionadas)
	_cerrar_libres()


func _sortear_troneras() -> Array[int]:
	var modo := int(patron)
	if modo == Patron.ALEATORIO:
		modo = _azar.randi_range(Patron.UN_LADO, Patron.TODAS)
	var indices: Array[int] = []
	if modo == Patron.UN_LADO:
		indices.assign(LADOS[_azar.randi_range(0, LADOS.size() - 1)])
	elif modo == Patron.TODAS:
		indices.assign([0, 1, 2, 3, 4, 5])
	else:
		var disponibles := [0, 1, 2, 3, 4, 5]
		for i in range(_azar.randi_range(1, 5)):
			indices.append(disponibles.pop_at(_azar.randi_range(0, disponibles.size() - 1)))
	return indices


func _cerrar_libres() -> void:
	for indice in _pendientes.duplicate():
		var tapa := _tapas[indice]
		if not _esta_libre(tapa):
			continue
		tapa.get_node("Colision").disabled = false
		tapa.show()
		_pendientes.erase(indice)


func _esta_libre(tapa: StaticBody3D) -> bool:
	for bola in get_tree().get_nodes_in_group("bolas_color") + get_tree().get_nodes_in_group("blanca"):
		if bola.is_queued_for_deletion() or not bola.visible:
			continue
		var radio := 0.14
		for hijo in bola.get_children():
			if hijo is CollisionShape3D and hijo.shape is SphereShape3D:
				radio = hijo.shape.radius
		var local := tapa.to_local(bola.global_position)
		var cercano := local.clamp(-TAMANO / 2.0, TAMANO / 2.0)
		if local.distance_to(cercano) < radio + 0.04:
			return false
	return true


func desactivar_troneras() -> void:
	powerup_troneras_activo = false
	_pendientes.clear()
	seleccionadas.clear()
	for tapa in _tapas:
		tapa.get_node("Colision").disabled = true
		tapa.hide()
	# Si una bola estaba apoyada contra una tapa, vuelve a simularse.
	for bola in get_tree().get_nodes_in_group("bolas_color") + get_tree().get_nodes_in_group("blanca"):
		if not bola.is_queued_for_deletion() and not bola.freeze:
			bola.sleeping = false

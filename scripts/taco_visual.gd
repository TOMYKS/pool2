extends Node3D

## Solo mueve el modelo: nunca el cuerpo físico ni el cálculo del golpe.
@export_range(0.0, 20.0, 0.5) var inclinacion_minima := 3.0
@export_range(20.0, 50.0, 1.0) var inclinacion_maxima := 35.0
@export var margen_visual := 0.006

var _largo := 0.0
var _radio := 0.0
var _punto := Vector3.ZERO
var _base := Basis.IDENTITY
var _direccion_fisica := Vector3.ZERO
var _preparado := false
@onready var cuerpo: AnimatableBody3D = get_parent()


func _ready() -> void:
	var modelo := get_child(0) as MeshInstance3D
	var limites: AABB = modelo.transform * modelo.get_aabb()
	_largo = limites.size.z
	_radio = maxf(limites.size.x, limites.size.y) * 0.5


func preparar(punto: Vector3, retiro_maximo: float) -> void:
	_punto = punto
	_direccion_fisica = -cuerpo.global_basis.z.normalized()
	var base_horizontal := cuerpo.global_basis.orthonormalized()
	var angulo := inclinacion_minima
	# Elegir UNA inclinación considerando el recorrido completo antes de tirar.
	# Si no hay espacio, conservar el ángulo máximo sin desplazar el apuntado.
	while true:
		_base = base_horizontal * Basis(Vector3.RIGHT, -deg_to_rad(angulo))
		if _recorrido_libre(retiro_maximo) or angulo >= inclinacion_maxima:
			break
		angulo = minf(angulo + 2.0, inclinacion_maxima)
	_preparado = true
	actualizar()


func _physics_process(_delta: float) -> void:
	if cuerpo.is_visible_in_tree():
		actualizar()


func actualizar() -> void:
	if not _preparado:
		return
	# La punta visual se desliza sobre el eje inclinado que pasa por la marca.
	# Al contactar, llega a esa marca. No se vuelve a orientar al retirar el palo.
	var distancia := maxf(0.0, (_punto - cuerpo.global_position).dot(_direccion_fisica) - 0.114)
	global_transform = Transform3D(_base, _punto + _base.z * distancia)


func _recorrido_libre(retiro_maximo: float) -> bool:
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.collision_mask = 3
	consulta.margin = 0.0
	var excluidos: Array[RID] = [cuerpo.get_rid()]
	for blanca in get_tree().get_nodes_in_group("blanca"):
		excluidos.append(blanca.get_rid())
	consulta.exclude = excluidos
	var sala := cuerpo.get_parent()
	var mesa := sala.get_node("Mesa")
	var poderes := sala.get_node_or_null("Powerups")
	# Segmentos de grosor creciente: no tratar la punta fina como el mango.
	# Extender la envolvente cubre también el retroceso máximo del modelo.
	var fin := _largo + retiro_maximo
	for tramo in range(20):
		var inicio := lerpf(0.03, fin, tramo / 20.0)
		var final := lerpf(0.03, fin, (tramo + 1) / 20.0)
		var forma := CapsuleShape3D.new()
		forma.radius = lerpf(0.011, _radio, minf(final / _largo, 1.0)) + margen_visual
		forma.height = final - inicio + forma.radius * 2.0
		consulta.shape = forma
		consulta.transform = Transform3D(Basis(_base.x, _base.z, _base.x.cross(_base.z)), _punto + _base.z * ((inicio + final) * 0.5))
		for choque in get_world_3d().direct_space_state.intersect_shape(consulta, 32):
			var obstaculo: Node = choque.collider
			# Muebles del bar y decoración no deben levantar el taco.
			if obstaculo.is_in_group("bolas_color") or mesa.is_ancestor_of(obstaculo) or (poderes != null and poderes.is_ancestor_of(obstaculo)):
				return false
	return true
